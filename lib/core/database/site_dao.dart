import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/sites/models/site_model.dart';
import 'database_helper.dart';
import 'sqlite_compat.dart';

class SiteDao {
  final DatabaseHelper _dbHelper;

  SiteDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insertSite(SiteModel site) async {
    final db = await _dbHelper.database;
    await db.insert(
      'sites',
      sqliteWriteMap(site.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSite(SiteModel site) async {
    final db = await _dbHelper.database;
    await db.update(
      'sites',
      sqliteWriteMap(site.toMap()),
      where: 'id = ?',
      whereArgs: [site.id],
    );
  }

  Future<void> softDeleteSite(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'sites',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SiteModel>> getSitesForCustomer(String customerId) async {
    final db = await _dbHelper.database;

    if (kIsWeb) {
      final customerRows = (await db.query('customers'))
          .where((r) => sqliteRequiredString(r['id']) == customerId)
          .toList();
      final customerName =
          customerRows.isNotEmpty ? sqliteString(customerRows.first['name']) : null;
      final sites = (await db.query('sites'))
          .where((r) =>
              sqliteRequiredString(r['customer_id']) == customerId &&
              !sqliteRowIsDeleted(r))
          .map((r) {
            final m = Map<String, dynamic>.from(r);
            m['customer_name'] = customerName;
            return SiteModel.fromMap(m);
          })
          .toList();
      sites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sites;
    }

    final results = await db.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sites s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.customer_id = ? AND s.deleted_at IS NULL
      ORDER BY s.created_at DESC
    ''', [customerId]);
    return results.map((m) => SiteModel.fromMap(m)).toList();
  }

  Future<List<SiteModel>> getAllActiveSites() async {
    final db = await _dbHelper.database;

    if (kIsWeb) {
      final siteRows = await db.query('sites');
      final custRows = await db.query('customers');
      final customerNames = {
        for (final c in custRows)
          sqliteRequiredString(c['id']): sqliteString(c['name']),
      };
      final sites = siteRows
          .where((r) => !sqliteRowIsDeleted(r))
          .map((r) {
            final m = Map<String, dynamic>.from(r);
            m['customer_name'] = customerNames[sqliteRequiredString(m['customer_id'])];
            return SiteModel.fromMap(m);
          })
          .toList();
      sites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sites;
    }

    final results = await db.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sites s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.deleted_at IS NULL
      ORDER BY s.created_at DESC
    ''');
    return results.map((m) => SiteModel.fromMap(m)).toList();
  }

  Future<SiteModel?> getSiteById(String id) async {
    final db = await _dbHelper.database;

    if (kIsWeb) {
      final rows = (await db.query('sites'))
          .where((r) => sqliteRequiredString(r['id']) == id)
          .toList();
      if (rows.isEmpty) return null;
      final m = Map<String, dynamic>.from(rows.first);
      final customerId = sqliteRequiredString(m['customer_id']);
      final custRows = (await db.query('customers'))
          .where((r) => sqliteRequiredString(r['id']) == customerId)
          .toList();
      if (custRows.isNotEmpty) m['customer_name'] = custRows.first['name'];
      return SiteModel.fromMap(m);
    }

    final results = await db.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sites s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
      LIMIT 1
    ''', [id]);
    if (results.isEmpty) return null;
    return SiteModel.fromMap(results.first);
  }

  Future<List<SiteModel>> getPendingSyncSites() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'sites',
      where: "sync_status = 'pending'",
    );
    return results.map((m) => SiteModel.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'sites',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
