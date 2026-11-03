import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/crypto/qr_decryptor.dart';
import '../../../core/utils/uuid.dart';
import '../../../local_db/cards_dao.dart';
import '../../../local_db/entries_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../attendees/services/attendee_service.dart';
import '../../events/providers/event_provider.dart';
import '../../events/services/event_service.dart';
import '../models/card_status.dart';
import '../models/scan_result.dart';

final scannerProvider = Provider<ScannerController>((ref) {
  return ScannerController(ref);
});

/// How long Admit waits for the server before saving the entry on the phone
/// instead — short, so a weak network doesn't hold up the door.
const _liveAdmitTimeout = Duration(seconds: 4);

/// How long a scan waits to fetch a card the phone hasn't seen yet.
const _lookupTimeout = Duration(seconds: 3);

class ScannerController {
  ScannerController(this._ref);

  final Ref _ref;
  final _cardsDao = CardsDao();
  final _entriesDao = EntriesDao();

  /// Reads a scanned code and returns the card's places. Nothing is
  /// recorded until [admit].
  Future<ScanResult> processScan(String rawValue) async {
    final eventId = _ref.read(activeEventIdProvider);
    if (eventId == null) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final keyHex = await _ref.read(keyVaultProvider).get(eventId);
    if (keyHex == null || keyHex.isEmpty) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final decrypted = await QrDecryptor.decrypt(rawValue.trim(), keyHex);
    if (decrypted == null || decrypted.eventId != eventId) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final card = await _cardStatus(
      eventId: eventId,
      qrToken: decrypted.qrToken,
      name: decrypted.name,
      phone: decrypted.phone,
    );
    return _resultFor(card, method: 'scan');
  }

  /// Check-in from the guest list, for when a QR will not scan.
  Future<ScanResult> manualLookup(AttendeeRecord attendee) async {
    final eventId = _ref.read(activeEventIdProvider);
    if (eventId == null) {
      return const ScanResult(type: ScanResultType.invalid);
    }

    final card = await _cardStatus(
      eventId: eventId,
      qrToken: attendee.qrToken,
      name: attendee.name,
      phone: attendee.phone,
      category: attendee.categoryName,
    );
    return _resultFor(card, method: 'manual');
  }

  Future<ScanResult> _resultFor(
    CardStatus card, {
    required String method,
  }) async {
    var current = card;
    // A full card may only look full because the phone's copy is stale
    // (an entry voided in the portal, places raised) — check once.
    if (current.isFull && await _isOnline()) {
      await _refreshGuestList(current.eventId);
      current = await _cardStatus(
        eventId: current.eventId,
        qrToken: current.qrToken,
        name: current.name,
        phone: current.phone,
        category: current.category,
        fetchIfMissing: false,
      );
    }
    return ScanResult(
      type: current.isFull ? ScanResultType.full : ScanResultType.ready,
      card: current,
      method: method,
    );
  }

  /// Admits [count] people on [card]. Goes straight to the server when it
  /// can, so a forwarded or reused card is refused at the gate; when the
  /// server can't be reached in time, the entry is saved on the phone and
  /// synced later.
  Future<AdmitResult> admit(
    CardStatus card, {
    required int count,
    required String method,
  }) async {
    final entryId = uuidV4();
    final scannedAt = DateTime.now();

    Future<void> saveEntry(int synced) => _entriesDao.insert(
      id: entryId,
      qrToken: card.qrToken,
      eventId: card.eventId,
      name: card.name,
      phone: card.phone,
      category: card.category,
      count: count,
      method: method,
      scannedAt: scannedAt,
      synced: synced,
    );

    if (await _isOnline()) {
      try {
        final response = await _ref
            .read(apiClientProvider)
            .post<Map<String, dynamic>>(
              ApiConfig.checkInPath,
              data: {
                'qrToken': card.qrToken,
                'eventId': card.eventId,
                'method': method,
                'entryId': entryId,
                'count': count,
                'scannedAt': scannedAt.toUtc().toIso8601String(),
              },
            )
            .timeout(_liveAdmitTimeout);

        final body = response.data ?? const {};
        // A server from before card places existed answers a repeat scan
        // with alreadyCheckedIn and no outcome: the card was already used.
        if (body['outcome'] == null && body['alreadyCheckedIn'] == true) {
          return AdmitResult(
            outcome: AdmitOutcome.refused,
            card: await _afterServerReply(card, body),
            message: 'Already checked in',
          );
        }

        await saveEntry(EntrySync.synced);
        return AdmitResult(
          outcome: AdmitOutcome.admitted,
          card: await _afterServerReply(card, body),
        );
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        final body = error.response?.data;
        if (status != null &&
            status >= 400 &&
            status < 500 &&
            status != 401 &&
            status != 408 &&
            status != 429) {
          return AdmitResult(
            outcome: AdmitOutcome.refused,
            card: await _afterServerReply(
              card,
              body is Map<String, dynamic> ? body : const {},
            ),
            message: body is Map && body['error'] is String
                ? body['error'] as String
                : 'The server refused this check-in',
          );
        }
      } catch (_) {
        // Timed out — fall through and keep it on the phone. If the
        // request did reach the server, the sync's retry with the same
        // entry id is counted once.
      }
    }

    await saveEntry(EntrySync.waiting);
    return AdmitResult(
      outcome: AdmitOutcome.queued,
      card: await _cardStatus(
        eventId: card.eventId,
        qrToken: card.qrToken,
        name: card.name,
        phone: card.phone,
        category: card.category,
        fetchIfMissing: false,
      ),
    );
  }

  /// Stores the card's numbers from a check-in reply and returns the card
  /// as it now stands, with the server's entry list when it sent one.
  Future<CardStatus> _afterServerReply(
    CardStatus card,
    Map<String, dynamic> body,
  ) async {
    final server = body['card'];
    if (server is! Map<String, dynamic>) {
      return _cardStatus(
        eventId: card.eventId,
        qrToken: card.qrToken,
        name: card.name,
        phone: card.phone,
        category: card.category,
        fetchIfMissing: false,
      );
    }

    final entries = [
      for (final entry in (server['entries'] as List<dynamic>? ?? const []))
        if (entry is Map<String, dynamic>)
          EntryLine(
            count: entry['count'] as int? ?? 1,
            at: DateTime.parse(entry['scannedAt'] as String),
            byName: entry['checkedInByName'] as String?,
          ),
    ];
    final admits = server['admits'] as int? ?? card.admits;
    final entered = server['entered'] as int? ?? card.serverEntered;
    await _cardsDao.updateTotals(
      qrToken: card.qrToken,
      eventId: card.eventId,
      admits: admits,
      entered: entered,
      firstEntryAt: entries.isEmpty ? null : entries.first.at,
    );

    final waiting = await _entriesDao.waitingPeopleForCard(
      card.qrToken,
      card.eventId,
    );
    return CardStatus(
      qrToken: card.qrToken,
      eventId: card.eventId,
      name: card.name,
      phone: card.phone,
      category: card.category,
      admits: admits,
      serverEntered: entered,
      waitingHere: waiting,
      known: true,
      entries: entries,
    );
  }

  Future<CardStatus> _cardStatus({
    required String eventId,
    required String qrToken,
    required String name,
    required String phone,
    String? category,
    bool fetchIfMissing = true,
  }) async {
    var row = await _cardsDao.get(qrToken, eventId);
    if (row == null && fetchIfMissing && await _isOnline()) {
      await _refreshGuestList(eventId);
      row = await _cardsDao.get(qrToken, eventId);
    }

    final local = await _entriesDao.forCard(qrToken, eventId);
    final waiting = local
        .where((e) => e['synced'] == EntrySync.waiting)
        .fold<int>(0, (sum, e) => sum + (e['count'] as int));

    final localTimes = [
      for (final e in local) DateTime.parse(e['scanned_at'] as String),
    ];
    final firstAt = DateTime.tryParse(row?['first_entry_at'] as String? ?? '');
    final entries = <EntryLine>[
      // The server's first entry (count unknown here: 0), unless it is one
      // this phone made — the server keeps the phone's time to the ms.
      if (firstAt != null &&
          localTimes.every(
            (t) => t.difference(firstAt).inMilliseconds.abs() > 1000,
          ))
        EntryLine(count: 0, at: firstAt),
      for (final e in local)
        EntryLine(
          count: e['count'] as int,
          at: DateTime.parse(e['scanned_at'] as String),
          waiting: e['synced'] == EntrySync.waiting,
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    if (row == null) {
      // Not in the phone's guest list: places unknown. Count only what this
      // phone admitted, against a single place.
      final admittedHere = local.fold<int>(
        0,
        (sum, e) => sum + (e['count'] as int),
      );
      return CardStatus(
        qrToken: qrToken,
        eventId: eventId,
        name: name,
        phone: phone,
        category: category,
        admits: 1,
        serverEntered: admittedHere - waiting,
        waitingHere: waiting,
        known: false,
        entries: entries,
      );
    }

    return CardStatus(
      qrToken: qrToken,
      eventId: eventId,
      name: row['name'] as String,
      phone: row['phone'] as String,
      category: row['category'] as String? ?? category,
      admits: row['admits'] as int,
      serverEntered: row['server_entered'] as int,
      waitingHere: waiting,
      known: true,
      entries: entries,
    );
  }

  Future<void> _refreshGuestList(String eventId) async {
    try {
      await _ref
          .read(attendeeServiceProvider)
          .fetchAttendees(eventId)
          .timeout(_lookupTimeout);
    } catch (_) {}
  }

  Future<bool> _isOnline() => _ref.read(connectivityServiceProvider).isOnline();
}

/// Entries still waiting to reach the server, across events.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return EntriesDao().waitingCount();
});

/// People admitted on this phone for the event that the server hasn't
/// counted yet — added to the server's totals on the dashboard.
final waitingPeopleProvider = FutureProvider.family<int, String>((
  ref,
  eventId,
) async {
  return EntriesDao().waitingPeopleForEvent(eventId);
});

final recentCheckinsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      eventId,
    ) async {
      return EntriesDao().recent(eventId: eventId);
    });
