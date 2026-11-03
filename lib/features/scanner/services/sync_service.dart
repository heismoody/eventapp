import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../local_db/cards_dao.dart';
import '../../../local_db/entries_dao.dart';
import '../../../shared/services/connectivity_service.dart';
import '../../attendees/services/attendee_service.dart';
import '../../events/providers/event_provider.dart';
import '../providers/scanner_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

const _syncRequestTimeout = Duration(seconds: 8);

class SyncService {
  SyncService(this._ref);

  final Ref _ref;
  final _entriesDao = EntriesDao();
  final _cardsDao = CardsDao();
  Future<int>? _running;

  /// Sends every entry still waiting on this phone. Concurrent calls share
  /// one run. Returns how many reached the server.
  Future<int> drainQueue() => _running ??= _drain().whenComplete(() {
    _running = null;
  });

  Future<int> _drain() async {
    final online = await _ref.read(connectivityServiceProvider).isOnline();
    if (!online) return 0;

    final waiting = await _entriesDao.waiting();
    var synced = 0;

    for (final entry in waiting) {
      final id = entry['id'] as String;
      try {
        final response = await _ref
            .read(apiClientProvider)
            .post<Map<String, dynamic>>(
              ApiConfig.checkInPath,
              data: {
                'qrToken': entry['qr_token'],
                'eventId': entry['event_id'],
                'method': entry['method'],
                'entryId': id,
                'count': entry['count'],
                'scannedAt': DateTime.parse(
                  entry['scanned_at'] as String,
                ).toUtc().toIso8601String(),
                // Late: the people are already inside, so the server keeps
                // it even past the card's places and flags the card instead.
                'sync': true,
              },
            )
            .timeout(_syncRequestTimeout);

        await _entriesDao.markSynced(id);
        await _storeCardTotals(entry, response.data);
        synced++;
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401) break; // Signed out — resumes after sign-in.
        if (status != null &&
            status >= 400 &&
            status < 500 &&
            status != 408 &&
            status != 429) {
          // Permanent (guest removed, no access): retrying can't help.
          final body = error.response?.data;
          await _entriesDao.markRejected(
            id,
            body is Map && body['error'] is String
                ? body['error'] as String
                : 'Refused by the server ($status)',
          );
          continue;
        }
        await _entriesDao.recordFailedAttempt(id, error.message ?? '$status');
        // No network after all, or the server is down: the rest would fail
        // the same way, one timeout each. Try again on the next trigger.
        if (status == null) break;
      } catch (error) {
        await _entriesDao.recordFailedAttempt(id, error.toString());
        break;
      }
    }

    if (waiting.isNotEmpty) _invalidateCounts();
    return synced;
  }

  Future<void> _storeCardTotals(
    Map<String, Object?> entry,
    Map<String, dynamic>? body,
  ) async {
    final card = body?['card'];
    if (card is! Map<String, dynamic>) return;
    await _cardsDao.updateTotals(
      qrToken: entry['qr_token'] as String,
      eventId: entry['event_id'] as String,
      admits: card['admits'] as int? ?? 1,
      entered: card['entered'] as int? ?? 0,
    );
  }

  void _invalidateCounts() {
    _ref.invalidate(pendingSyncCountProvider);
    final eventId = _ref.read(activeEventIdProvider);
    if (eventId != null) {
      _ref.invalidate(waitingPeopleProvider(eventId));
      _ref.invalidate(recentCheckinsProvider(eventId));
      _ref.invalidate(attendeesProvider(eventId));
    }
  }
}

/// Keeps entries flowing to the server without anyone pressing sync: on
/// start, when the app comes back to the foreground, when the network
/// returns, and every 30 seconds while anything is waiting. Watched by the
/// main shell, so it lives as long as someone is signed in.
final syncCoordinatorProvider = Provider<void>((ref) {
  final sync = ref.read(syncServiceProvider);
  final entries = EntriesDao();

  Future<void> drainIfWaiting() async {
    if (await entries.waitingCount() > 0) await sync.drainQueue();
  }

  final timer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => drainIfWaiting(),
  );
  final connectivity = ref
      .read(connectivityServiceProvider)
      .onStatusChanged
      .listen((online) {
        if (online) drainIfWaiting();
      });
  final lifecycle = AppLifecycleListener(onResume: drainIfWaiting);
  unawaited(drainIfWaiting());

  ref.onDispose(() {
    timer.cancel();
    connectivity.cancel();
    lifecycle.dispose();
  });
});
