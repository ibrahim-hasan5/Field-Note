import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'field_notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Customers Table
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

    // Sites Table
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

    // Field Notes Table
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

    // Indexes for speed
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
