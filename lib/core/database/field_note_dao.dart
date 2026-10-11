import 'package:sqflite/sqflite.dart';
import '../../features/field_notes/models/field_note_model.dart';
import 'database_helper.dart';

class FieldNoteDao {
  final DatabaseHelper _dbHelper;

  FieldNoteDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insertNote(FieldNoteModel note) async {
    final db = await _dbHelper.database;
    await db.insert(
      'field_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(FieldNoteModel note) async {
    final db = await _dbHelper.database;
    await db.update(
      'field_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> softDeleteNote(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'field_notes',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FieldNoteModel>> getAllActiveNotes({
    String? siteId,
    String? status,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>['n.deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (siteId != null && siteId.isNotEmpty) {
      whereClauses.add('n.site_id = ?');
      whereArgs.add(siteId);
    }

    if (status != null && status.isNotEmpty) {
      whereClauses.add('n.status = ?');
      whereArgs.add(status);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(n.title LIKE ? OR n.description LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final whereString = whereClauses.join(' AND ');

    final results = await db.rawQuery('''
      SELECT n.*, s.name as site_name, c.name as customer_name
      FROM field_notes n
      LEFT JOIN sites s ON n.site_id = s.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE $whereString
      ORDER BY n.note_date DESC
    ''', whereArgs);

    return results.map((m) => FieldNoteModel.fromMap(m)).toList();
  }

  Future<FieldNoteModel?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT n.*, s.name as site_name, c.name as customer_name
      FROM field_notes n
      LEFT JOIN sites s ON n.site_id = s.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE n.id = ?
      LIMIT 1
    ''', [id]);

    if (results.isEmpty) return null;
    return FieldNoteModel.fromMap(results.first);
  }

  Future<List<FieldNoteModel>> getPendingSyncNotes() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'field_notes',
      where: "sync_status = 'pending'",
    );
    return results.map((m) => FieldNoteModel.fromMap(m)).toList();
  }

  Future<void> markSynced(String id, {String? photoUrl}) async {
    final db = await _dbHelper.database;
    final updateMap = <String, dynamic>{'sync_status': 'synced'};
    if (photoUrl != null) {
      updateMap['photo_url'] = photoUrl;
    }
    await db.update(
      'field_notes',
      updateMap,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
