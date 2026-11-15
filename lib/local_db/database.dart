import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../core/utils/uuid.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'eventsys_scanner.db');

    return openDatabase(
      path,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE sync_queue ADD COLUMN method TEXT NOT NULL DEFAULT 'scan'",
          );
        }
        if (oldVersion < 3) {
          await _createCardTables(db);
          await _carryOverOldCheckIns(db);
        }
      },
      onCreate: (db, version) async {
        // checkin_history and sync_queue are the pre-v3 tables: one row per
        // card. They are no longer written, but kept so an upgrade never
        // drops data.
        await db.execute('''
          CREATE TABLE checkin_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            qr_token TEXT NOT NULL,
            event_id TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            contribution TEXT,
            checked_in_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            UNIQUE(qr_token, event_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            qr_token TEXT NOT NULL,
            event_id TEXT NOT NULL,
            checked_in_at TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 0,
            method TEXT NOT NULL DEFAULT 'scan',
            UNIQUE(qr_token, event_id)
          )
        ''');

        await _createCardTables(db);
      },
    );
  }

  /// cards: the event's guest list as last fetched, so a scan can show a
  /// card's places offline. entries: every admit made on this phone, each
  /// with its own id; a card can have several.
  static Future<void> _createCardTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cards (
        qr_token TEXT NOT NULL,
        event_id TEXT NOT NULL,
        attendee_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        category TEXT,
        admits INTEGER NOT NULL DEFAULT 1,
        server_entered INTEGER NOT NULL DEFAULT 0,
        first_entry_at TEXT,
        PRIMARY KEY (qr_token, event_id)
      )
    ''');

    // synced: 0 = waiting, 1 = on the server, 2 = the server refused it
    // for good (see last_error) — not retried.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entries (
        id TEXT PRIMARY KEY,
        qr_token TEXT NOT NULL,
        event_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        category TEXT,
        count INTEGER NOT NULL,
        method TEXT NOT NULL DEFAULT 'scan',
        scanned_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS entries_card_idx ON entries (event_id, qr_token)',
    );
  }

  /// Copies pre-v3 check-ins into entries as one-person admits, so history
  /// still shows and anything not yet sent still gets sent. The old rows
  /// stay where they are.
  static Future<void> _carryOverOldCheckIns(Database db) async {
    final history = await db.query('checkin_history');
    final pending = await db.query('sync_queue', where: 'synced = 0');
    final pendingMethods = {
      for (final row in pending)
        '${row['event_id']}|${row['qr_token']}': row['method'] as String,
    };

    final batch = db.batch();
    for (final row in history) {
      final key = '${row['event_id']}|${row['qr_token']}';
      final waiting = pendingMethods.containsKey(key);
      batch.insert('entries', {
        'id': uuidV4(),
        'qr_token': row['qr_token'],
        'event_id': row['event_id'],
        'name': row['name'],
        'phone': row['phone'],
        'count': 1,
        'method': pendingMethods[key] ?? 'scan',
        'scanned_at': row['checked_in_at'],
        'synced': waiting ? 0 : 1,
      });
    }
    // The old queue is handed over to entries — mark it done so nothing
    // sends these twice.
    batch.update('sync_queue', {'synced': 1}, where: 'synced = 0');
    await batch.commit(noResult: true);
  }
}
