import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: (db, version) async {
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
            UNIQUE(qr_token, event_id)
          )
        ''');
      },
    );
  }
}
