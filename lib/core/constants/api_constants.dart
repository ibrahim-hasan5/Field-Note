class ApiConstants {
  // Default to localhost for Android emulator (10.0.2.2) or local / ngrok
  // In development with real device: replace with machine IP (e.g. http://192.168.0.xxx:8080) or ngrok url
  static const String baseUrl = 'http://10.0.2.2:8080/api';

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
