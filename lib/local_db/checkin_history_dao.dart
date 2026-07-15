import 'package:sqflite/sqflite.dart';

import 'database.dart';

class CheckinHistoryDao {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<void> insert({
    required String qrToken,
    required String eventId,
    required String name,
    required String phone,
    String? contribution,
    required DateTime checkedInAt,
    bool synced = false,
  }) async {
    final db = await _db;
    await db.insert(
      'checkin_history',
      {
        'qr_token': qrToken,
        'event_id': eventId,
        'name': name,
        'phone': phone,
        'contribution': contribution,
        'checked_in_at': checkedInAt.toIso8601String(),
        'synced': synced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> exists(String qrToken, String eventId) async {
    final db = await _db;
    final rows = await db.query(
      'checkin_history',
      where: 'qr_token = ? AND event_id = ?',
      whereArgs: [qrToken, eventId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getByQrToken(String qrToken, String eventId) async {
    final db = await _db;
    final rows = await db.query(
      'checkin_history',
      where: 'qr_token = ? AND event_id = ?',
      whereArgs: [qrToken, eventId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAll({String? eventId}) async {
    final db = await _db;
    if (eventId != null) {
      return db.query(
        'checkin_history',
        where: 'event_id = ?',
        whereArgs: [eventId],
        orderBy: 'checked_in_at DESC',
      );
    }
    return db.query('checkin_history', orderBy: 'checked_in_at DESC');
  }

  Future<int> countForEvent(String eventId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM checkin_history WHERE event_id = ?',
      [eventId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSynced(String qrToken, String eventId) async {
    final db = await _db;
    await db.update(
      'checkin_history',
      {'synced': 1},
      where: 'qr_token = ? AND event_id = ?',
      whereArgs: [qrToken, eventId],
    );
  }
}
