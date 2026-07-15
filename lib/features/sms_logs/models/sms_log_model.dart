class SmsLogModel {
  const SmsLogModel({
    required this.id,
    required this.attendeeName,
    required this.phone,
    required this.message,
    required this.status,
    required this.sentAt,
    this.beemRequestId,
  });

  final String id;
  final String attendeeName;
  final String phone;
  final String message;
  final String status;
  final DateTime sentAt;
  final String? beemRequestId;

  factory SmsLogModel.fromJson(Map<String, dynamic> json) {
    return SmsLogModel(
      id: json['id'] as String,
      attendeeName: (json['attendeeName'] as String?) ?? 'Unknown',
      phone: (json['phone'] as String?) ?? '',
      message: json['message'] as String,
      status: json['status'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      beemRequestId: json['beemRequestId'] as String?,
    );
  }
}
