class ContributionCategory {
  const ContributionCategory({
    required this.id,
    required this.eventId,
    required this.name,
  });

  final String id;
  final String eventId;
  final String name;

  factory ContributionCategory.fromJson(Map<String, dynamic> json) {
    return ContributionCategory(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
    );
  }
}

/// One individual dated payment — distinct from [ContributionCategory]
/// (just a guest-grouping tag) and from an attendee's running total. Used
/// to chart contributions received per day.
class ContributionRecord {
  const ContributionRecord({
    required this.id,
    required this.attendeeId,
    required this.amountTzs,
    required this.createdAt,
  });

  final String id;
  final String attendeeId;
  final String amountTzs;
  final DateTime createdAt;

  double get amountValue => double.tryParse(amountTzs) ?? 0;

  factory ContributionRecord.fromJson(Map<String, dynamic> json) {
    return ContributionRecord(
      id: json['id'] as String,
      attendeeId: json['attendeeId'] as String,
      amountTzs: json['amountTzs'].toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
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
