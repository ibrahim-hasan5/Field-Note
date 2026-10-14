import 'package:flutter/foundation.dart';

/// Chrome (sqflite_common_ffi_web) throws
/// `Unsupported operation: unsupported result null (null)` for:
/// - `WHERE col IS NULL`
/// - `LIMIT`
/// - `IN (...)` in some cases
/// - SQL NULL cells (GPS, photos, deleted_at) in result rows
///
/// Native SQLite is fine; these helpers only change the web path.
Map<String, Object?> sqliteWriteMap(Map<String, dynamic> map) {
  if (!kIsWeb) {
    return Map<String, Object?>.from(map);
  }
  return {for (final e in map.entries) e.key: e.value ?? ''};
}

bool sqliteRowIsDeleted(Map<String, Object?> row) {
  final value = row['deleted_at'];
  if (value == null) return false;
  return value.toString().trim().isNotEmpty;
}

String sqliteRequiredString(Object? value) => value?.toString() ?? '';

String? sqliteString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

double? sqliteDouble(Object? value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
