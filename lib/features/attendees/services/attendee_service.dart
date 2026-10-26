import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';

enum ContributionPaymentStatus { unpaid, partial, paid, none }

class AttendeeRecord {
  const AttendeeRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.qrToken,
    required this.checkedIn,
    this.checkedInAt,
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
  final String? contributionAmount;
  final String? categoryId;
  final String? categoryName;
  final String? targetAmount;
  final String? balance;
  final bool fullyPaid;
  final DateTime? qrActivatedAt;
  final DateTime? createdAt;

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
    await _cacheCategories(eventId, records);
    return records;
  }

  static String _categoryCacheKey(String eventId) =>
      'guest_categories_$eventId';

  Future<void> _cacheCategories(
    String eventId,
    List<AttendeeRecord> records,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {for (final r in records) r.qrToken: r.categoryName ?? ''};
      await prefs.setString(_categoryCacheKey(eventId), jsonEncode(map));
    } catch (_) {}
  }

  Future<String?> _cachedCategory(String eventId, String qrToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_categoryCacheKey(eventId));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (!map.containsKey(qrToken)) return null;
      final name = map[qrToken] as String?;
      return (name == null || name.isEmpty) ? '' : name;
    } catch (_) {
      return null;
    }
  }

  /// Category for the door screen. Reads the on-phone cache first so scanning
  /// works offline; if the guest isn't cached yet, refreshes the guest list
  /// (short timeout) and reads the cache again. Returns null when unknown.
  Future<String?> categoryFor(String eventId, String qrToken) async {
    var cached = await _cachedCategory(eventId, qrToken);
    if (cached == null) {
      try {
        await fetchAttendees(eventId).timeout(const Duration(seconds: 3));
        cached = await _cachedCategory(eventId, qrToken);
      } catch (_) {}
    }
    return (cached == null || cached.isEmpty) ? null : cached;
  }

  Future<void> updateAttendee({
    required String attendeeId,
    required String name,
    required String phone,
    String? categoryId,
    required String contributionAmount,
    required String pledgeAmount,
  }) async {
    final dio = _ref.read(apiClientProvider);
    await dio.patch(
      ApiConfig.attendeePatchPath(attendeeId),
      data: {
        'name': name,
        'phone': phone,
        'categoryId': categoryId,
        'contributionAmount': contributionAmount,
        'pledgeAmount': pledgeAmount,
      },
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
  }) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.post(
      ApiConfig.attendeesImportPath,
      data: {
        'eventId': eventId,
        'categoryId': categoryId,
        'contacts': [
          {'name': name, 'phone': phone},
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
