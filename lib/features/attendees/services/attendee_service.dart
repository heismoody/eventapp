import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return attendees
        .map((e) => AttendeeRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAttendee({
    required String attendeeId,
    required String name,
    required String phone,
    String? categoryId,
    required String contributionAmount,
  }) async {
    final dio = _ref.read(apiClientProvider);
    await dio.patch(
      ApiConfig.attendeePatchPath(attendeeId),
      data: {
        'name': name,
        'phone': phone,
        'categoryId': categoryId,
        'contributionAmount': contributionAmount,
      },
    );
  }
}

final attendeesProvider = FutureProvider.family<List<AttendeeRecord>, String>((ref, eventId) async {
  return ref.read(attendeeServiceProvider).fetchAttendees(eventId);
});
