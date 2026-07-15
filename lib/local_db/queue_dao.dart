import 'package:sqflite/sqflite.dart';

import 'database.dart';

class QueueDao {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<void> enqueue({
    required String qrToken,
    required String eventId,
    required DateTime checkedInAt,
  }) async {
    final db = await _db;
    await db.insert(
      'sync_queue',
      {
        'qr_token': qrToken,
        'event_id': eventId,
        'checked_in_at': checkedInAt.toIso8601String(),
        'attempts': 0,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final db = await _db;
    return db.query(
      'sync_queue',
      where: 'synced = 0',
      orderBy: 'id ASC',
    );
  }

  Future<int> pendingCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSynced(int id) async {
    final db = await _db;
    await db.update('sync_queue', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementAttempts(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }
}
