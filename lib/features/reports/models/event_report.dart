/// Mirrors the portal's `EventReport` shape (lib/event-report.ts) — same
/// numbers the web admin report shows, plus a mobile-only `contributions`
/// section the portal report doesn't display.
class EventReport {
  const EventReport({
    required this.generatedAt,
    required this.event,
    required this.totals,
    required this.people,
    required this.categories,
    required this.checkIns,
    required this.registrations,
    this.messaging,
    this.contributions,
  });

  final DateTime generatedAt;
  final ReportEvent event;

  /// Card counts, as before.
  final ReportTotals totals;

  /// Attendance in people (a Couple card counts 2).
  final ReportPeople people;
  final List<ReportCategoryRow> categories;
  final ReportTimeline checkIns;
  final ReportTimeline registrations;
  final ReportMessaging? messaging;
  final ReportContributions? contributions;

  factory EventReport.fromJson(Map<String, dynamic> json) {
    final totals = ReportTotals.fromJson(
      json['totals'] as Map<String, dynamic>,
    );
    return EventReport(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      event: ReportEvent.fromJson(json['event'] as Map<String, dynamic>),
      totals: totals,
      people: json['people'] is Map<String, dynamic>
          ? ReportPeople.fromJson(json['people'] as Map<String, dynamic>)
          : ReportPeople.fromCards(totals),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => ReportCategoryRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkIns: ReportTimeline.fromJson(
        json['checkIns'] as Map<String, dynamic>,
      ),
      registrations: ReportTimeline.fromJson(
        json['registrations'] as Map<String, dynamic>,
      ),
      messaging: json['messaging'] == null
          ? null
          : ReportMessaging.fromJson(json['messaging'] as Map<String, dynamic>),
      contributions: json['contributions'] == null
          ? null
          : ReportContributions.fromJson(
              json['contributions'] as Map<String, dynamic>,
            ),
    );
  }
}

class ReportEvent {
  const ReportEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.venue,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime date;
  final String? venue;

  factory ReportEvent.fromJson(Map<String, dynamic> json) {
    return ReportEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      venue: json['venue'] as String?,
    );
  }
}

class ReportTotals {
  const ReportTotals({
    required this.registered,
    required this.checkedIn,
    required this.notCheckedIn,
    required this.checkInRate,
    required this.cardsAssigned,
    required this.cardsActivated,
    required this.withoutCategory,
  });

  final int registered;
  final int checkedIn;
  final int notCheckedIn;
  final double checkInRate;
  final int cardsAssigned;
  final int cardsActivated;
  final int withoutCategory;

  factory ReportTotals.fromJson(Map<String, dynamic> json) {
    return ReportTotals(
      registered: json['registered'] as int,
      checkedIn: json['checkedIn'] as int,
      notCheckedIn: json['notCheckedIn'] as int,
      checkInRate: (json['checkInRate'] as num).toDouble(),
      cardsAssigned: json['cardsAssigned'] as int,
      cardsActivated: json['cardsActivated'] as int,
      withoutCategory: json['withoutCategory'] as int,
    );
  }
}

/// Attendance in people. `entered` is capped at each card's places, with
/// anyone beyond them in `over`, so entered + notEntered = expected.
class ReportPeople {
  const ReportPeople({
    required this.expected,
    required this.entered,
    required this.notEntered,
    required this.over,
    required this.rate,
    required this.cardsPartial,
    required this.cardsNotArrived,
  });

  final int expected;
  final int entered;
  final int notEntered;
  final int over;
  final double rate;
  final int cardsPartial;
  final int cardsNotArrived;

  factory ReportPeople.fromJson(Map<String, dynamic> json) => ReportPeople(
    expected: json['expected'] as int,
    entered: json['entered'] as int,
    notEntered: json['notEntered'] as int,
    over: json['over'] as int? ?? 0,
    rate: (json['rate'] as num).toDouble(),
    cardsPartial: json['cardsPartial'] as int? ?? 0,
    cardsNotArrived: json['cardsNotArrived'] as int? ?? 0,
  );

  /// A server from before card places: every card is one person.
  factory ReportPeople.fromCards(ReportTotals totals) => ReportPeople(
    expected: totals.registered,
    entered: totals.checkedIn,
    notEntered: totals.notCheckedIn,
    over: 0,
    rate: totals.checkInRate,
    cardsPartial: 0,
    cardsNotArrived: totals.notCheckedIn,
  );
}

class ReportCategoryRow {
  const ReportCategoryRow({
    required this.id,
    required this.name,
    required this.attendees,
    required this.checkedIn,
    required this.peopleExpected,
    required this.peopleEntered,
  });

  final String? id;
  final String name;

  /// Cards, and cards with someone in.
  final int attendees;
  final int checkedIn;

  /// People the cards admit, and people in.
  final int peopleExpected;
  final int peopleEntered;

  factory ReportCategoryRow.fromJson(Map<String, dynamic> json) {
    final attendees = json['attendees'] as int;
    final checkedIn = json['checkedIn'] as int;
    return ReportCategoryRow(
      id: json['id'] as String?,
      name: json['name'] as String,
      attendees: attendees,
      checkedIn: checkedIn,
      peopleExpected: json['peopleExpected'] as int? ?? attendees,
      peopleEntered: json['peopleEntered'] as int? ?? checkedIn,
    );
  }
}

class ReportTimeBucket {
  const ReportTimeBucket({required this.hour, required this.count});

  final DateTime hour;
  final int count;

  factory ReportTimeBucket.fromJson(Map<String, dynamic> json) {
    return ReportTimeBucket(
      hour: DateTime.parse(json['hour'] as String),
      count: json['count'] as int,
    );
  }
}

class ReportTimeline {
  const ReportTimeline({
    required this.first,
    required this.last,
    required this.buckets,
  });

  final DateTime? first;
  final DateTime? last;
  final List<ReportTimeBucket> buckets;

  factory ReportTimeline.fromJson(Map<String, dynamic> json) {
    return ReportTimeline(
      first: json['first'] == null
          ? null
          : DateTime.parse(json['first'] as String),
      last: json['last'] == null
          ? null
          : DateTime.parse(json['last'] as String),
      buckets: (json['buckets'] as List<dynamic>)
          .map((e) => ReportTimeBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReportChannelStats {
  const ReportChannelStats({
    required this.channel,
    required this.sent,
    required this.failed,
    required this.pending,
    required this.purchased,
    required this.available,
  });

  final String channel;
  final int sent;
  final int failed;
  final int pending;
  final int purchased;
  final int available;

  factory ReportChannelStats.fromJson(Map<String, dynamic> json) {
    return ReportChannelStats(
      channel: json['channel'] as String,
      sent: json['sent'] as int,
      failed: json['failed'] as int,
      pending: json['pending'] as int,
      purchased: json['purchased'] as int,
      available: json['available'] as int,
    );
  }
}

class ReportMessageTypeStats {
  const ReportMessageTypeStats({
    required this.type,
    required this.sent,
    required this.failed,
    required this.pending,
  });

  final String type;
  final int sent;
  final int failed;
  final int pending;

  factory ReportMessageTypeStats.fromJson(Map<String, dynamic> json) {
    return ReportMessageTypeStats(
      type: json['type'] as String,
      sent: json['sent'] as int,
      failed: json['failed'] as int,
      pending: json['pending'] as int,
    );
  }
}

class ReportMessageDetail {
  const ReportMessageDetail({
    required this.id,
    required this.channel,
    required this.recipientName,
    required this.recipientPhone,
    required this.status,
    required this.type,
    required this.messagePreview,
    required this.failureReason,
    required this.createdAt,
  });

  final String id;
  final String channel;
  final String recipientName;
  final String? recipientPhone;
  final String status;
  final String type;
  final String messagePreview;
  final String? failureReason;
  final DateTime createdAt;

  factory ReportMessageDetail.fromJson(Map<String, dynamic> json) {
    return ReportMessageDetail(
      id: json['id'] as String,
      channel: json['channel'] as String,
      recipientName: json['recipientName'] as String,
      recipientPhone: json['recipientPhone'] as String?,
      status: json['status'] as String,
      type: json['type'] as String,
      messagePreview: json['messagePreview'] as String,
      failureReason: json['failureReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ReportMessaging {
  const ReportMessaging({
    required this.channels,
    required this.byType,
    required this.attendeesReached,
    required this.peopleReached,
    required this.messages,
  });

  final List<ReportChannelStats> channels;
  final List<ReportMessageTypeStats> byType;
  final int attendeesReached;

  /// Main guests plus companions delivered to.
  final int peopleReached;
  final List<ReportMessageDetail> messages;

  factory ReportMessaging.fromJson(Map<String, dynamic> json) {
    return ReportMessaging(
      channels: (json['channels'] as List<dynamic>)
          .map((e) => ReportChannelStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      byType: (json['byType'] as List<dynamic>)
          .map(
            (e) => ReportMessageTypeStats.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      attendeesReached: json['attendeesReached'] as int,
      peopleReached:
          json['peopleReached'] as int? ?? json['attendeesReached'] as int,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => ReportMessageDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReportContributionCategoryRow {
  const ReportContributionCategoryRow({
    required this.id,
    required this.name,
    required this.expected,
    required this.collected,
  });

  final String? id;
  final String name;
  final double expected;
  final double collected;

  factory ReportContributionCategoryRow.fromJson(Map<String, dynamic> json) {
    return ReportContributionCategoryRow(
      id: json['id'] as String?,
      name: json['name'] as String,
      expected: (json['expected'] as num).toDouble(),
      collected: (json['collected'] as num).toDouble(),
    );
  }
}

class ReportContributions {
  const ReportContributions({
    required this.totalExpected,
    required this.totalCollected,
    required this.fullyPaidCount,
    required this.partialCount,
    required this.unpaidCount,
    required this.categories,
  });

  final double totalExpected;
  final double totalCollected;
  final int fullyPaidCount;
  final int partialCount;
  final int unpaidCount;
  final List<ReportContributionCategoryRow> categories;

  factory ReportContributions.fromJson(Map<String, dynamic> json) {
    return ReportContributions(
      totalExpected: (json['totalExpected'] as num).toDouble(),
      totalCollected: (json['totalCollected'] as num).toDouble(),
      fullyPaidCount: json['fullyPaidCount'] as int,
      partialCount: json['partialCount'] as int,
      unpaidCount: json['unpaidCount'] as int,
      categories: (json['categories'] as List<dynamic>)
          .map(
            (e) => ReportContributionCategoryRow.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
