import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static late final SettingsRepository instance;
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance = SettingsRepository(prefs);
  }

  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyOfflineMode = 'force_offline_mode';
  static const String _keyDefaultStatus = 'default_note_status';
  static const String _keyAutoSync = 'auto_sync_enabled';

  bool isDarkMode() => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  bool isOfflineMode() => _prefs.getBool(_keyOfflineMode) ?? false;
  Future<void> setOfflineMode(bool value) => _prefs.setBool(_keyOfflineMode, value);

  String getDefaultNoteStatus() => _prefs.getString(_keyDefaultStatus) ?? 'DRAFT';
  Future<void> setDefaultNoteStatus(String value) => _prefs.setString(_keyDefaultStatus, value);

  bool isAutoSyncEnabled() => _prefs.getBool(_keyAutoSync) ?? true;
  Future<void> setAutoSyncEnabled(bool value) => _prefs.setBool(_keyAutoSync, value);
}
