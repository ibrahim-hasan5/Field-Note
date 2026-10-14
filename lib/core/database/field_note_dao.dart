import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/field_notes/models/field_note_model.dart';
import 'database_helper.dart';
import 'sqlite_compat.dart';

class FieldNoteDao {
  final DatabaseHelper _dbHelper;

  FieldNoteDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insertNote(FieldNoteModel note) async {
    final db = await _dbHelper.database;
    await db.insert(
      'field_notes',
      sqliteWriteMap(note.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(FieldNoteModel note) async {
    final db = await _dbHelper.database;
    await db.update(
      'field_notes',
      sqliteWriteMap(note.toMap()),
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

    // Web (sqflite_common_ffi_web) does not support rawQuery with LEFT JOINs.
    // Use platform-specific code paths.
    if (kIsWeb) {
      return _getAllActiveNotesWeb(
        db,
        siteId: siteId,
        status: status,
        searchQuery: searchQuery,
      );
    }

    // Native: use the fast JOIN query
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
    final results = await db.rawQuery(
      '''
      SELECT n.*, s.name as site_name, c.name as customer_name
      FROM field_notes n
      LEFT JOIN sites s ON n.site_id = s.id
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE $whereString
      ORDER BY n.note_date DESC
      ''',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return results.map((m) => FieldNoteModel.fromMap(m)).toList();
  }

  /// Web-safe version: table scans + Dart filters (no IS NULL / IN / LIMIT).
  Future<List<FieldNoteModel>> _getAllActiveNotesWeb(
    Database db, {
    String? siteId,
    String? status,
    String? searchQuery,
  }) async {
    final noteRows = await db.query('field_notes');
    final siteRows = await db.query('sites');
    final customerRows = await db.query('customers');

    final siteMap = {
      for (final s in siteRows) sqliteRequiredString(s['id']): s,
    };
    final customerMap = {
      for (final c in customerRows) sqliteRequiredString(c['id']): c,
    };

    var notes = noteRows.where((row) => !sqliteRowIsDeleted(row)).map((noteRow) {
      final mutable = Map<String, dynamic>.from(noteRow);
      final site = siteMap[sqliteRequiredString(mutable['site_id'])];
      if (site != null) {
        mutable['site_name'] = site['name'];
        final customer = customerMap[sqliteRequiredString(site['customer_id'])];
        if (customer != null) {
          mutable['customer_name'] = customer['name'];
        }
      }
      return FieldNoteModel.fromMap(mutable);
    }).toList();

    if (siteId != null && siteId.isNotEmpty) {
      notes = notes.where((n) => n.siteId == siteId).toList();
    }
    if (status != null && status.isNotEmpty) {
      notes = notes.where((n) => n.status == status).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      notes = notes
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              (n.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    notes.sort((a, b) => b.noteDate.compareTo(a.noteDate));
    return notes;
  }

  Future<FieldNoteModel?> getNoteById(String id) async {
    final db = await _dbHelper.database;

    if (kIsWeb) {
      final rows = (await db.query('field_notes'))
          .where((r) => sqliteRequiredString(r['id']) == id)
          .toList();
      if (rows.isEmpty) return null;
      final mutable = Map<String, dynamic>.from(rows.first);
      final siteId = sqliteRequiredString(mutable['site_id']);
      final siteRows = (await db.query('sites'))
          .where((r) => sqliteRequiredString(r['id']) == siteId)
          .toList();
      if (siteRows.isNotEmpty) {
        mutable['site_name'] = siteRows.first['name'];
        final customerId = sqliteRequiredString(siteRows.first['customer_id']);
        final custRows = (await db.query('customers'))
            .where((r) => sqliteRequiredString(r['id']) == customerId)
            .toList();
        if (custRows.isNotEmpty) {
          mutable['customer_name'] = custRows.first['name'];
        }
      }
      return FieldNoteModel.fromMap(mutable);
    }

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
