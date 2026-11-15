import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';
import '../../../local_db/cards_dao.dart';

enum ContributionPaymentStatus { unpaid, partial, paid, none }

/// Someone sharing a guest's card. With a phone they can be sent the same
/// invitation; entry is still counted against the card's places.
class Companion {
  const Companion({this.id, this.name, this.phone});

  final String? id;
  final String? name;
  final String? phone;

  factory Companion.fromJson(Map<String, dynamic> json) => Companion(
    id: json['id'] as String?,
    name: json['name'] as String?,
    phone: json['phone'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': ?id, 'name': name, 'phone': phone};
}

/// A companion's number that someone else in the event already has.
class PhoneConflict {
  const PhoneConflict({
    required this.phone,
    required this.attendeeId,
    required this.attendeeName,
    required this.isGuest,
    required this.canMerge,
  });

  final String phone;
  final String attendeeId;
  final String attendeeName;

  /// A separate guest (true), or a companion on another card (false).
  final bool isGuest;
  final bool canMerge;

  factory PhoneConflict.fromJson(Map<String, dynamic> json) => PhoneConflict(
    phone: json['phone'] as String,
    attendeeId: json['attendeeId'] as String,
    attendeeName: json['attendeeName'] as String,
    isGuest: json['kind'] == 'guest',
    canMerge: json['canMerge'] as bool? ?? false,
  );
}

class AttendeeRecord {
  const AttendeeRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.qrToken,
    required this.checkedIn,
    this.checkedInAt,
    this.admits = 1,
    this.enteredCount = 0,
    this.companions = const [],
    this.contributionAmount,
    this.categoryId,
    this.categoryName,
    this.targetAmount,
    this.balance,
    this.fullyPaid = false,
    this.qrActivatedAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String qrToken;
  final bool checkedIn;
  final DateTime? checkedInAt;

  /// People this card admits, and people the server has counted in so far.
  final int admits;
  final int enteredCount;
  final List<Companion> companions;
  final String? contributionAmount;
  final String? categoryId;
  final String? categoryName;
  final String? targetAmount;
  final String? balance;
  final bool fullyPaid;
  final DateTime? qrActivatedAt;
  final DateTime? createdAt;

  int get placesLeft => math.max(0, admits - enteredCount);
  bool get isPartlyEntered => enteredCount > 0 && placesLeft > 0;

  double get paidAmount => double.tryParse(contributionAmount ?? '') ?? 0;
  double get targetAmountValue => double.tryParse(targetAmount ?? '') ?? 0;
  double get balanceAmount => double.tryParse(balance ?? '') ?? 0;

  ContributionPaymentStatus get paymentStatus {
    if (targetAmountValue <= 0) return ContributionPaymentStatus.none;
    if (fullyPaid || balanceAmount <= 0) return ContributionPaymentStatus.paid;
    if (paidAmount > 0) return ContributionPaymentStatus.partial;
    return ContributionPaymentStatus.unpaid;
  }

  factory AttendeeRecord.fromJson(Map<String, dynamic> json) {
    return AttendeeRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      qrToken: json['qrToken'] as String,
      checkedIn: json['checkedIn'] as bool,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      // Servers from before card places existed send neither: a card is
      // then one person, entered once checked in.
      admits: json['admits'] as int? ?? 1,
      enteredCount:
          json['enteredCount'] as int? ?? ((json['checkedIn'] as bool) ? 1 : 0),
      companions: [
        for (final item in (json['companions'] as List<dynamic>? ?? const []))
          Companion.fromJson(item as Map<String, dynamic>),
      ],
      contributionAmount: json['contributionAmount'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      targetAmount: json['targetAmount']?.toString(),
      balance: json['balance']?.toString(),
      fullyPaid: json['fullyPaid'] as bool? ?? false,
      qrActivatedAt: json['qrActivatedAt'] != null
          ? DateTime.parse(json['qrActivatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

final attendeeServiceProvider = Provider<AttendeeService>((ref) {
  return AttendeeService(ref);
});

class AttendeeService {
  AttendeeService(this._ref);

  final Ref _ref;

  Future<List<AttendeeRecord>> fetchAttendees(String eventId) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get(
      ApiConfig.attendeesPath,
      queryParameters: {'eventId': eventId},
    );
    final data = response.data as Map<String, dynamic>;
    final attendees = data['attendees'] as List<dynamic>;
    final records = attendees
        .map((e) => AttendeeRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    await _cacheCards(eventId, records);
    return records;
  }

  /// Keeps the phone's copy of the guest list, so a scan can show a card's
  /// places with no network.
  Future<void> _cacheCards(String eventId, List<AttendeeRecord> records) async {
    try {
      await CardsDao().replaceForEvent(eventId, [
        for (final r in records)
          {
            'qr_token': r.qrToken,
            'attendee_id': r.id,
            'name': r.name,
            'phone': r.phone,
            'category': r.categoryName,
            'admits': r.admits,
            'server_entered': r.enteredCount,
            'first_entry_at': r.checkedInAt?.toIso8601String(),
          },
      ]);
    } catch (_) {}
  }

  Future<void> updateAttendee({
    required String attendeeId,
    required String name,
    required String phone,
    String? categoryId,
    required String contributionAmount,
    required String pledgeAmount,

    /// Sent only when changed by hand; otherwise a type change carries a
    /// card on its old type's default over to the new type's default.
    int? admits,
  }) async {
    final dio = _ref.read(apiClientProvider);
    await dio.patch(
      ApiConfig.attendeePatchPath(attendeeId),
      data: {
        'name': name,
        'phone': phone,
        'categoryId': categoryId,
        'admits': ?admits,
        'contributionAmount': contributionAmount,
        'pledgeAmount': pledgeAmount,
      },
    );
  }

  /// Replaces the card's companions. Returns numbers someone else in the
  /// event already has, so the caller can offer to merge them.
  Future<List<PhoneConflict>> saveCompanions({
    required String attendeeId,
    required List<Companion> companions,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.put(
      ApiConfig.attendeeCompanionsPath(attendeeId),
      data: {'companions': companions.map((c) => c.toJson()).toList()},
    );
    final data = response.data as Map<String, dynamic>;
    return [
      for (final item in (data['conflicts'] as List<dynamic>? ?? const []))
        PhoneConflict.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Folds the separate guest [guestId] into this card as a companion.
  Future<void> mergeGuestIntoCard({
    required String cardId,
    required String guestId,
  }) async {
    final dio = _ref.read(apiClientProvider);
    await dio.post(
      ApiConfig.attendeeMergePath(cardId),
      data: {'guestId': guestId},
    );
  }

  /// Adds a single guest by hand, without picking them from the phone's
  /// contacts. Reuses the bulk import endpoint with a one-item list, since
  /// that endpoint already dedupes by phone number per event.
  Future<void> addGuest({
    required String eventId,
    required String name,
    required String phone,
    String? categoryId,

    /// Omitted: the card type's default.
    int? admits,
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post(
      ApiConfig.attendeesImportPath,
      data: {
        'eventId': eventId,
        'categoryId': categoryId,
        'contacts': [
          {'name': name, 'phone': phone, 'admits': ?admits},
        ],
      },
    );
    final data = response.data as Map<String, dynamic>;
    final inserted = data['inserted'] as int? ?? 0;
    if (inserted == 0) {
      throw StateError('A guest with this phone number already exists');
    }
  }
}

final attendeesProvider = FutureProvider.family<List<AttendeeRecord>, String>((
  ref,
  eventId,
) async {
  return ref.read(attendeeServiceProvider).fetchAttendees(eventId);
});
