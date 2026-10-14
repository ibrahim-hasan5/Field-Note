import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/customers/models/customer_model.dart';
import 'database_helper.dart';
import 'sqlite_compat.dart';

class CustomerDao {
  final DatabaseHelper _dbHelper;

  CustomerDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> insertCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    await db.insert(
      'customers',
      sqliteWriteMap(customer.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      sqliteWriteMap(customer.toMap()),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> softDeleteCustomer(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CustomerModel>> getAllActiveCustomers() async {
    final db = await _dbHelper.database;
    if (kIsWeb) {
      final results = await db.query('customers');
      final active = results
          .where((row) => !sqliteRowIsDeleted(row))
          .map((m) => CustomerModel.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return active;
    }
    final results = await db.query(
      'customers',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return results.map((m) => CustomerModel.fromMap(m)).toList();
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    if (kIsWeb) {
      final results = (await db.query('customers'))
          .where((row) => sqliteRequiredString(row['id']) == id)
          .toList();
      if (results.isEmpty) return null;
      return CustomerModel.fromMap(Map<String, dynamic>.from(results.first));
    }
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CustomerModel.fromMap(results.first);
  }

  Future<List<CustomerModel>> getPendingSyncCustomers() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'customers',
      where: "sync_status = 'pending'",
    );
    return results.map((m) => CustomerModel.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
