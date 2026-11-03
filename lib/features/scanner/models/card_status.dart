import 'dart:math' as math;

/// One admit on a card, as shown on the result sheet.
class EntryLine {
  const EntryLine({
    required this.count,
    required this.at,
    this.byName,
    this.waiting = false,
  });

  final int count;
  final DateTime at;

  /// Who admitted them, when the server told us.
  final String? byName;

  /// Admitted on this phone, not yet on the server.
  final bool waiting;
}

/// A card's places as this phone knows them: the server's count from the
/// last refresh plus this phone's entries the server hasn't counted yet.
class CardStatus {
  const CardStatus({
    required this.qrToken,
    required this.eventId,
    required this.name,
    required this.phone,
    this.category,
    required this.admits,
    required this.serverEntered,
    required this.waitingHere,
    required this.known,
    this.entries = const [],
  });

  final String qrToken;
  final String eventId;
  final String name;
  final String phone;
  final String? category;
  final int admits;
  final int serverEntered;
  final int waitingHere;

  /// False when the card isn't in the phone's guest list (added after the
  /// last refresh, and the phone couldn't reach the server): its places
  /// are unknown, so only one person is offered.
  final bool known;

  final List<EntryLine> entries;

  int get entered => serverEntered + waitingHere;
  int get placesLeft => math.max(0, admits - entered);
  bool get isFull => placesLeft == 0;
  int get over => math.max(0, entered - admits);
}
