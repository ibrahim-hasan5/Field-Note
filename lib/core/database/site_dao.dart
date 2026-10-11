import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/sites/models/site_model.dart';
import 'database_helper.dart';

class SiteDao {
  final DatabaseHelper _dbHelper;

  SiteDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insertSite(SiteModel site) async {
    final db = await _dbHelper.database;
    await db.insert(
      'sites',
      site.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSite(SiteModel site) async {
    final db = await _dbHelper.database;
    await db.update(
      'sites',
      site.toMap(),
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
      final siteRows = await db.query(
        'sites',
        where: 'customer_id = ? AND deleted_at IS NULL',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );
      if (siteRows.isEmpty) return [];
      final custRows = await db.query('customers', where: 'id = ?', whereArgs: [customerId], limit: 1);
      final customerName = custRows.isNotEmpty ? custRows.first['name'] as String? : null;
      return siteRows.map((r) {
        final m = Map<String, dynamic>.from(r);
        m['customer_name'] = customerName;
        return SiteModel.fromMap(m);
      }).toList();
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
      final siteRows = await db.query(
        'sites',
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
      if (siteRows.isEmpty) return [];

      // Fetch all customers needed
      final customerIds = siteRows
          .map((s) => s['customer_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      Map<String, String?> customerNames = {};
      if (customerIds.isNotEmpty) {
        final placeholders = List.filled(customerIds.length, '?').join(', ');
        final custRows = await db.query(
          'customers',
          where: 'id IN ($placeholders)',
          whereArgs: customerIds,
        );
        customerNames = {for (final c in custRows) c['id'] as String: c['name'] as String?};
      }

      return siteRows.map((r) {
        final m = Map<String, dynamic>.from(r);
        m['customer_name'] = customerNames[m['customer_id']];
        return SiteModel.fromMap(m);
      }).toList();
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
      final rows = await db.query('sites', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      final m = Map<String, dynamic>.from(rows.first);
      final custRows = await db.query('customers', where: 'id = ?', whereArgs: [m['customer_id']], limit: 1);
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
