import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  // Bump version whenever schema changes — forces onUpgrade on existing DBs
  static const int _dbVersion = 3;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // On web: databaseFactory was already set to databaseFactoryFfiWeb
      // in main.dart before this is called. Use the global openDatabase
      // which respects whatever factory is set.
      return await openDatabase(
        'field_notes.db',
        version: _dbVersion,
        onCreate: _onCreateWeb,
        onUpgrade: _onUpgradeWeb,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'field_notes.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ──────────────────────────────────────────────
  // WEB — no FOREIGN KEY, no CREATE INDEX
  // sqflite_common_ffi_web throws "Unsupported operation: unsupported
  // result null (null)" on those SQL constructs.
  // ──────────────────────────────────────────────

  Future<void> _onCreateWeb(Database db, int version) async {
    await _createTablesWeb(db);
  }

  Future<void> _onUpgradeWeb(Database db, int oldVersion, int newVersion) async {
    // Drop and recreate for a clean slate during development
    await db.execute('DROP TABLE IF EXISTS field_notes');
    await db.execute('DROP TABLE IF EXISTS sites');
    await db.execute('DROP TABLE IF EXISTS customers');
    await _createTablesWeb(db);
  }

  Future<void> _createTablesWeb(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sites (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS field_notes (
        id TEXT PRIMARY KEY,
        site_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        latitude REAL,
        longitude REAL,
        note_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        photo_path TEXT,
        photo_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
  }

  // ──────────────────────────────────────────────
  // NATIVE (Android / iOS / Windows / macOS)
  // Full schema with FOREIGN KEY constraints and indexes.
  // ──────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await _createTablesNative(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS field_notes');
    await db.execute('DROP TABLE IF EXISTS sites');
    await db.execute('DROP TABLE IF EXISTS customers');
    await _createTablesNative(db);
    await _createIndexes(db);
  }

  Future<void> _createTablesNative(Database db) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE sites (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE field_notes (
        id TEXT PRIMARY KEY,
        site_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        latitude REAL,
        longitude REAL,
        note_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        photo_path TEXT,
        photo_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_sites_customer ON sites(customer_id)');
    await db.execute('CREATE INDEX idx_notes_site ON field_notes(site_id)');
    await db.execute('CREATE INDEX idx_notes_status ON field_notes(status)');
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
  }
}
