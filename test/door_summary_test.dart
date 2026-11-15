import 'package:flutter_test/flutter_test.dart';

import 'package:eventapp/features/scanner/models/door_summary.dart';

Map<String, Object?> card(
  String token,
  String name, {
  String? category,
  int admits = 1,
  int entered = 0,
  String? firstEntryAt,
}) => {
  'qr_token': token,
  'attendee_id': 'id-$token',
  'name': name,
  'phone': '255700000000',
  'category': category,
  'admits': admits,
  'server_entered': entered,
  'first_entry_at': firstEntryAt,
};

Map<String, Object?> entry(
  String token, {
  int count = 1,
  int synced = 0,
  String at = '2026-11-07T18:00:00',
  String name = 'Walk-in',
  String? category,
}) => {
  'qr_token': token,
  'name': name,
  'phone': '255711111111',
  'category': category,
  'count': count,
  'synced': synced,
  'scanned_at': at,
};

void main() {
  test('counts people per card type, with entries waiting on this phone', () {
    final summary = DoorSummary.build(
      cardRows: [
        card(
          'a',
          'Amina',
          category: 'Double',
          admits: 2,
          entered: 1,
          firstEntryAt: '2026-11-07T17:00:00',
        ),
        card('b', 'Baraka', category: 'Double', admits: 2),
        card('c', 'Chausiku', category: 'Single'),
        card('d', 'Daudi'),
      ],
      // One more person on Amina's card, admitted offline here.
      entryRows: [entry('a', at: '2026-11-07T18:30:00')],
    );

    expect(summary.peopleExpected, 6);
    expect(summary.peopleIn, 2);
    expect(summary.peopleToCome, 4);
    expect(summary.cardsArrived, 1);
    expect(summary.cardsPartlyIn, 0);
    expect(summary.waitingSync, 1);

    expect(summary.categories.map((c) => c.name).toList(), [
      'Double',
      'Single',
      DoorSummary.uncategorisedLabel,
    ]);
    final double = summary.categories.first;
    expect(double.peopleIn, 2);
    expect(double.peopleExpected, 4);
    expect(double.peopleToCome, 2);
    expect(double.cardsArrived, 1);

    final amina = summary.arrived().single;
    expect(amina.name, 'Amina');
    expect(amina.waiting, 1);
    expect(amina.lastEntryAt, DateTime.parse('2026-11-07T18:30:00'));
  });

  test('to come lists partly-in cards first and filters by type', () {
    final summary = DoorSummary.build(
      cardRows: [
        card('z', 'Zuhura', category: 'Double', admits: 2),
        card('y', 'Yusuf', category: 'Double', admits: 2, entered: 1),
        card('x', 'Xavier', category: 'Single'),
      ],
      entryRows: const [],
    );

    expect(summary.toCome().map((c) => c.name).toList(), [
      'Yusuf',
      'Xavier',
      'Zuhura',
    ]);
    expect(summary.toCome(category: 'Single').map((c) => c.name), ['Xavier']);
    expect(
      summary
          .toCome(category: DoorSummary.uncategorisedLabel)
          .map((c) => c.name),
      isEmpty,
    );
  });

  test('synced and over-admitted entries are not counted twice', () {
    final summary = DoorSummary.build(
      cardRows: [card('a', 'Amina', admits: 1, entered: 2)],
      // Already on the server (synced = 1), so already in server_entered.
      entryRows: [entry('a', synced: 1)],
    );
    expect(summary.peopleIn, 2);
    expect(summary.peopleToCome, 0);
    expect(summary.waitingSync, 0);
    expect(summary.progress, 1);
  });

  test('a card scanned here but missing from the guest list still counts', () {
    final summary = DoorSummary.build(
      cardRows: const [],
      entryRows: [entry('new', count: 2, name: 'New guest', category: 'VIP')],
    );
    expect(summary.isEmpty, isFalse);
    expect(summary.peopleIn, 2);
    expect(summary.peopleToCome, 0);
    final guest = summary.arrived().single;
    expect(guest.attendeeId, isNull);
    expect(guest.category, 'VIP');
  });
}
