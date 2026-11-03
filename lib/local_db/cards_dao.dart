import 'package:sqflite/sqflite.dart';

import 'database.dart';

class CardsDao {
  Future<Database> get _db => AppDatabase.instance.database;

  /// Replaces the event's cached guest list with a fresh one from the server.
  Future<void> replaceForEvent(
    String eventId,
    List<Map<String, Object?>> cards,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('cards', where: 'event_id = ?', whereArgs: [eventId]);
      final batch = txn.batch();
      for (final card in cards) {
        batch.insert('cards', {...card, 'event_id': eventId});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, Object?>?> get(String qrToken, String eventId) async {
    final db = await _db;
    final rows = await db.query(
      'cards',
      where: 'qr_token = ? AND event_id = ?',
      whereArgs: [qrToken, eventId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Takes the server's latest numbers for one card, as returned with a
  /// check-in, so the next scan sees them without a full refresh.
  Future<void> updateTotals({
    required String qrToken,
    required String eventId,
    required int admits,
    required int entered,
    DateTime? firstEntryAt,
  }) async {
    final db = await _db;
    await db.update(
      'cards',
      {
        'admits': admits,
        'server_entered': entered,
        'first_entry_at': ?firstEntryAt?.toIso8601String(),
      },
      where: 'qr_token = ? AND event_id = ?',
      whereArgs: [qrToken, eventId],
    );
  }
}
