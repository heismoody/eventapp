import 'dart:math' as math;
import '../../../l10n/l10n.dart';

/// A card as the door sees it: the server's count from the phone's copy of
/// the guest list, plus this phone's entries the server hasn't counted yet.
class DoorCard {
  const DoorCard({
    required this.qrToken,
    this.attendeeId,
    required this.name,
    required this.phone,
    this.category,
    required this.admits,
    required this.entered,
    required this.waiting,
    this.lastEntryAt,
  });

  final String qrToken;

  /// Null for a card scanned here that isn't in the phone's guest list yet.
  final String? attendeeId;
  final String name;
  final String phone;
  final String? category;

  /// People the card admits, and people in on it so far.
  final int admits;
  final int entered;

  /// People admitted on this phone, not yet on the server.
  final int waiting;
  final DateTime? lastEntryAt;

  int get placesLeft => math.max(0, admits - entered);
  bool get arrived => entered > 0;
  bool get partlyIn => entered > 0 && placesLeft > 0;
}

/// One card type's numbers, counted in people (a Double card admits 2).
class DoorCategory {
  const DoorCategory({
    required this.name,
    required this.isUncategorised,
    required this.cards,
    required this.cardsArrived,
    required this.peopleExpected,
    required this.peopleIn,
    required this.peopleToCome,
  });

  final String name;
  final bool isUncategorised;
  final int cards;
  final int cardsArrived;
  final int peopleExpected;
  final int peopleIn;
  final int peopleToCome;

  double get progress =>
      peopleExpected == 0 ? 0 : math.min(1, peopleIn / peopleExpected);
}

class DoorSummary {
  const DoorSummary({
    required this.cards,
    required this.categories,
    required this.peopleExpected,
    required this.peopleIn,
    required this.peopleToCome,
    required this.cardsArrived,
    required this.cardsPartlyIn,
    required this.waitingSync,
  });

  /// Groups and labels cards without a type, in the app language.
  static String get uncategorisedLabel => appL10n.noCardType;

  final List<DoorCard> cards;

  /// Largest card type first, cards without a type last.
  final List<DoorCategory> categories;

  final int peopleExpected;
  final int peopleIn;
  final int peopleToCome;
  final int cardsArrived;
  final int cardsPartlyIn;

  /// People admitted on this phone that haven't reached the server.
  final int waitingSync;

  bool get isEmpty => cards.isEmpty;

  double get progress =>
      peopleExpected == 0 ? 0 : math.min(1, peopleIn / peopleExpected);

  /// Cards with someone in, latest arrival first.
  List<DoorCard> arrived({String? category}) {
    final list = [
      for (final card in cards)
        if (card.arrived && _inCategory(card, category)) card,
    ];
    list.sort((a, b) {
      final at = a.lastEntryAt, bt = b.lastEntryAt;
      if (at == null && bt == null) return a.name.compareTo(b.name);
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return list;
  }

  /// Cards with places left, partly-in cards first, then by name.
  List<DoorCard> toCome({String? category}) {
    final list = [
      for (final card in cards)
        if (card.placesLeft > 0 && _inCategory(card, category)) card,
    ];
    list.sort((a, b) {
      if (a.partlyIn != b.partlyIn) return a.partlyIn ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  static bool _inCategory(DoorCard card, String? category) =>
      category == null || (card.category ?? uncategorisedLabel) == category;

  /// Builds the door's numbers from the phone's cached guest list (`cards`
  /// rows) and this phone's own entries (`entries` rows, refused ones
  /// already left out).
  factory DoorSummary.build({
    required List<Map<String, Object?>> cardRows,
    required List<Map<String, Object?>> entryRows,
  }) {
    final waitingByCard = <String, int>{};
    final lastLocalByCard = <String, DateTime>{};
    final entriesByCard = <String, List<Map<String, Object?>>>{};
    var waitingSync = 0;

    for (final entry in entryRows) {
      final token = entry['qr_token'] as String;
      final count = entry['count'] as int;
      entriesByCard.putIfAbsent(token, () => []).add(entry);
      if (entry['synced'] == 0) {
        waitingByCard[token] = (waitingByCard[token] ?? 0) + count;
        waitingSync += count;
      }
      final at = DateTime.tryParse(entry['scanned_at'] as String? ?? '');
      final last = lastLocalByCard[token];
      if (at != null && (last == null || at.isAfter(last))) {
        lastLocalByCard[token] = at;
      }
    }

    DateTime? latest(DateTime? a, DateTime? b) {
      if (a == null) return b;
      if (b == null) return a;
      return a.isAfter(b) ? a : b;
    }

    final cards = <DoorCard>[];
    final known = <String>{};
    for (final row in cardRows) {
      final token = row['qr_token'] as String;
      known.add(token);
      final waiting = waitingByCard[token] ?? 0;
      cards.add(
        DoorCard(
          qrToken: token,
          attendeeId: row['attendee_id'] as String?,
          name: row['name'] as String,
          phone: row['phone'] as String,
          category: row['category'] as String?,
          admits: row['admits'] as int,
          entered: (row['server_entered'] as int) + waiting,
          waiting: waiting,
          lastEntryAt: latest(
            DateTime.tryParse(row['first_entry_at'] as String? ?? ''),
            lastLocalByCard[token],
          ),
        ),
      );
    }

    // Cards scanned here that the phone's guest list doesn't have yet (added
    // after the last refresh): counted against what was admitted on them.
    for (final MapEntry(key: token, value: entries) in entriesByCard.entries) {
      if (known.contains(token)) continue;
      final first = entries.first;
      final entered = entries.fold<int>(0, (s, e) => s + (e['count'] as int));
      cards.add(
        DoorCard(
          qrToken: token,
          name: first['name'] as String,
          phone: first['phone'] as String,
          category: first['category'] as String?,
          admits: math.max(1, entered),
          entered: entered,
          waiting: waitingByCard[token] ?? 0,
          lastEntryAt: lastLocalByCard[token],
        ),
      );
    }

    final byCategory = <String, List<DoorCard>>{};
    for (final card in cards) {
      byCategory
          .putIfAbsent(card.category ?? uncategorisedLabel, () => [])
          .add(card);
    }
    final categories = [
      for (final MapEntry(key: name, value: group) in byCategory.entries)
        DoorCategory(
          name: name,
          isUncategorised: group.first.category == null,
          cards: group.length,
          cardsArrived: group.where((c) => c.arrived).length,
          peopleExpected: group.fold(0, (s, c) => s + c.admits),
          peopleIn: group.fold(0, (s, c) => s + c.entered),
          peopleToCome: group.fold(0, (s, c) => s + c.placesLeft),
        ),
    ];
    categories.sort((a, b) {
      if (a.isUncategorised != b.isUncategorised) {
        return a.isUncategorised ? 1 : -1;
      }
      final bySize = b.peopleExpected.compareTo(a.peopleExpected);
      return bySize != 0 ? bySize : a.name.compareTo(b.name);
    });

    return DoorSummary(
      cards: cards,
      categories: categories,
      peopleExpected: cards.fold(0, (s, c) => s + c.admits),
      peopleIn: cards.fold(0, (s, c) => s + c.entered),
      peopleToCome: cards.fold(0, (s, c) => s + c.placesLeft),
      cardsArrived: cards.where((c) => c.arrived).length,
      cardsPartlyIn: cards.where((c) => c.partlyIn).length,
      waitingSync: waitingSync,
    );
  }
}
