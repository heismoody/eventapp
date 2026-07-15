import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/api_config.dart';

class AttendeeRecord {
  const AttendeeRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.qrToken,
    required this.checkedIn,
    this.checkedInAt,
    this.contributionAmount,
  });

  final String id;
  final String name;
  final String phone;
  final String qrToken;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final String? contributionAmount;

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
}

final attendeesProvider = FutureProvider.family<List<AttendeeRecord>, String>((ref, eventId) async {
  return ref.read(attendeeServiceProvider).fetchAttendees(eventId);
});
