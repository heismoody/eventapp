import 'package:sqflite/sqflite.dart';

import 'database.dart';

/// Values of entries.synced.
abstract final class EntrySync {
  static const waiting = 0;
  static const synced = 1;
  static const rejected = 2;
}

class EntriesDao {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<void> insert({
    required String id,
    required String qrToken,
    required String eventId,
    required String name,
    required String phone,
    String? category,
    required int count,
    required String method,
    required DateTime scannedAt,
    required int synced,
  }) async {
    final db = await _db;
    await db.insert('entries', {
      'id': id,
      'qr_token': qrToken,
      'event_id': eventId,
      'name': name,
      'phone': phone,
      'category': category,
      'count': count,
      'method': method,
      'scanned_at': scannedAt.toIso8601String(),
      'synced': synced,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// This phone's entries for one card, oldest first.
  Future<List<Map<String, Object?>>> forCard(
    String qrToken,
    String eventId,
  ) async {
    final db = await _db;
    return db.query(
      'entries',
      where: 'qr_token = ? AND event_id = ? AND synced != ?',
      whereArgs: [qrToken, eventId, EntrySync.rejected],
      orderBy: 'scanned_at ASC',
    );
  }

  /// People admitted on this phone that the server hasn't counted yet.
  Future<int> waitingPeopleForCard(String qrToken, String eventId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) FROM entries '
      'WHERE qr_token = ? AND event_id = ? AND synced = ?',
      [qrToken, eventId, EntrySync.waiting],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> waitingPeopleForEvent(String eventId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(count), 0) FROM entries '
      'WHERE event_id = ? AND synced = ?',
      [eventId, EntrySync.waiting],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, Object?>>> waiting() async {
    final db = await _db;
    return db.query(
      'entries',
      where: 'synced = ?',
      whereArgs: [EntrySync.waiting],
      orderBy: 'scanned_at ASC',
    );
  }

  Future<int> waitingCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM entries WHERE synced = ?',
      [EntrySync.waiting],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, Object?>>> rejected() async {
    final db = await _db;
    return db.query(
      'entries',
      where: 'synced = ?',
      whereArgs: [EntrySync.rejected],
      orderBy: 'scanned_at DESC',
    );
  }

  /// Recent entries for history lists. `checked_in_at` is aliased for the
  /// screens that showed the pre-v3 history table.
  Future<List<Map<String, Object?>>> recent({required String eventId}) async {
    final db = await _db;
    return db.rawQuery(
      'SELECT *, scanned_at AS checked_in_at FROM entries '
      'WHERE event_id = ? AND synced != ? ORDER BY scanned_at DESC',
      [eventId, EntrySync.rejected],
    );
  }

  Future<void> markSynced(String id) async {
    final db = await _db;
    await db.update(
      'entries',
      {'synced': EntrySync.synced, 'last_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markRejected(String id, String reason) async {
    final db = await _db;
    await db.update(
      'entries',
      {'synced': EntrySync.rejected, 'last_error': reason},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recordFailedAttempt(String id, String error) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE entries SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }
}
