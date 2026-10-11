import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use http://localhost:8080/api for Chrome/Web/Desktop, or 10.0.2.2 for Android emulator
  static String get baseUrl => kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';

  // Auth
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';

  // Customers
  static const String customers = '/customers';

  // Sites
  static const String sites = '/sites';

  // Field Notes
  static const String notes = '/notes';

  // Sync
  static const String syncPull = '/sync/pull';
  static const String syncPush = '/sync/push';
}
