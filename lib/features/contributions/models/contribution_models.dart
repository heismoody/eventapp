class ContributionCategory {
  const ContributionCategory({
    required this.id,
    required this.eventId,
    required this.name,
    required this.targetAmount,
  });

  final String id;
  final String eventId;
  final String name;
  final String targetAmount;

  double get targetAmountValue => double.tryParse(targetAmount) ?? 0;

  factory ContributionCategory.fromJson(Map<String, dynamic> json) {
    return ContributionCategory(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      targetAmount: json['targetAmount'].toString(),
    );
  }
}

class AttendeeContributionUpdate {
  const AttendeeContributionUpdate({
    required this.balance,
    required this.fullyPaid,
    required this.newTotal,
    required this.attendee,
  });

  final String balance;
  final bool fullyPaid;
  final String newTotal;
  final Map<String, dynamic> attendee;

  factory AttendeeContributionUpdate.fromJson(Map<String, dynamic> json) {
    return AttendeeContributionUpdate(
      balance: json['balance'] as String,
      fullyPaid: json['fullyPaid'] as bool,
      newTotal: json['newTotal'] as String,
      attendee: json['attendee'] as Map<String, dynamic>,
    );
  }
}

class SmsBillingSummary {
  const SmsBillingSummary({
    required this.eventId,
    required this.totalSent,
    required this.totalFailed,
    required this.totalCostTzs,
    required this.breakdown,
  });

  final String eventId;
  final int totalSent;
  final int totalFailed;
  final int totalCostTzs;
  final Map<String, SmsBillingBreakdown> breakdown;

  factory SmsBillingSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    return SmsBillingSummary(
      eventId: json['eventId'] as String,
      totalSent: json['totalSent'] as int? ?? 0,
      totalFailed: json['totalFailed'] as int? ?? 0,
      totalCostTzs: json['totalCostTzs'] as int? ?? 0,
      breakdown: rawBreakdown.map(
        (key, value) => MapEntry(
          key,
          SmsBillingBreakdown.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class SmsBillingBreakdown {
  const SmsBillingBreakdown({required this.count, required this.cost});

  final int count;
  final int cost;

  factory SmsBillingBreakdown.fromJson(Map<String, dynamic> json) {
    return SmsBillingBreakdown(
      count: json['count'] as int? ?? 0,
      cost: json['cost'] as int? ?? 0,
    );
  }
}

class SmsSendResult {
  const SmsSendResult({
    required this.sent,
    required this.failed,
    required this.total,
    required this.totalCostTzs,
    this.allowed = true,
    this.error,
    this.code,
  });

  final int sent;
  final int failed;
  final int total;
  final int totalCostTzs;
  final bool allowed;
  final String? error;
  final String? code;

  factory SmsSendResult.fromJson(Map<String, dynamic> json) {
    return SmsSendResult(
      sent: json['sent'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      totalCostTzs: json['totalCostTzs'] as int? ?? 0,
      allowed: json['allowed'] as bool? ?? json['code'] != 'INSUFFICIENT_CREDITS',
      error: json['error'] as String?,
      code: json['code'] as String?,
    );
  }
}

class SmsCreditsSummary {
  const SmsCreditsSummary({
    required this.eventId,
    required this.allocated,
    required this.used,
    required this.available,
    this.required,
    this.canSend,
    this.message,
  });

  final String eventId;
  final int allocated;
  final int used;
  final int available;
  final int? required;
  final bool? canSend;
  final String? message;

  factory SmsCreditsSummary.fromJson(Map<String, dynamic> json) {
    return SmsCreditsSummary(
      eventId: json['eventId'] as String,
      allocated: json['allocated'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      required: json['required'] as int?,
      canSend: json['canSend'] as bool?,
      message: json['message'] as String?,
    );
  }
}

class SmsLogRecord {
  const SmsLogRecord({
    required this.id,
    required this.status,
    required this.message,
    required this.sentAt,
    this.attendeeId,
    this.attendeeName,
    this.phone,
    this.smsType,
    this.providerError,
  });

  final String id;
  final String status;
  final String message;
  final DateTime sentAt;
  final String? attendeeId;
  final String? attendeeName;
  final String? phone;
  final String? smsType;
  final String? providerError;

  factory SmsLogRecord.fromJson(Map<String, dynamic> json) {
    return SmsLogRecord(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String? ?? '',
      sentAt: DateTime.parse(json['sentAt'] as String),
      attendeeId: json['attendeeId'] as String?,
      attendeeName: json['attendeeName'] as String?,
      phone: json['phone'] as String?,
      smsType: json['smsType'] as String?,
      providerError: json['providerError'] as String?,
    );
  }
}

class PaymentSubmissionRecord {
  const PaymentSubmissionRecord({
    required this.id,
    required this.smsCount,
    required this.amountTzs,
    required this.status,
    required this.createdAt,
    required this.proofUrl,
    this.proofPublicId,
    this.submitterNotes,
    this.reviewNotes,
  });

  final String id;
  final int smsCount;
  final int amountTzs;
  final String status;
  final DateTime createdAt;
  final String proofUrl;
  final String? proofPublicId;
  final String? submitterNotes;
  final String? reviewNotes;

  factory PaymentSubmissionRecord.fromJson(Map<String, dynamic> json) {
    return PaymentSubmissionRecord(
      id: json['id'] as String,
      smsCount: json['smsCount'] as int? ?? 0,
      amountTzs: json['amountTzs'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
      proofUrl: json['proofUrl'] as String? ?? '',
      proofPublicId: json['proofPublicId'] as String?,
      submitterNotes: json['submitterNotes'] as String?,
      reviewNotes: json['reviewNotes'] as String?,
    );
  }
}

class PaymentProofUploadResult {
  const PaymentProofUploadResult({
    required this.url,
    required this.publicId,
  });

  final String url;
  final String publicId;

  factory PaymentProofUploadResult.fromJson(Map<String, dynamic> json) {
    return PaymentProofUploadResult(
      url: json['url'] as String,
      publicId: json['publicId'] as String,
    );
  }
}

class SmsTemplate {
  const SmsTemplate({
    required this.id,
    required this.eventId,
    required this.name,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String name;
  final String body;
  final DateTime createdAt;

  factory SmsTemplate.fromJson(Map<String, dynamic> json) {
    return SmsTemplate(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PaymentSubmitResult {
  const PaymentSubmitResult({
    required this.purchaseId,
    required this.smsCount,
    required this.amountTzs,
    required this.status,
    required this.message,
  });

  final String purchaseId;
  final int smsCount;
  final int amountTzs;
  final String status;
  final String message;

  factory PaymentSubmitResult.fromJson(Map<String, dynamic> json) {
    return PaymentSubmitResult(
      purchaseId: json['purchaseId'] as String,
      smsCount: json['smsCount'] as int? ?? 0,
      amountTzs: json['amountTzs'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String? ?? 'Payment submitted',
    );
  }
}
