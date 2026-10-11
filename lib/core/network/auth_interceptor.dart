import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  final FirebaseAuth _firebaseAuth;

  AuthInterceptor({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $idToken';
        }
      } catch (e) {
        // Fallthrough if token refresh fails
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 401 Unauthorized handling if needed
    }
    super.onError(err, handler);
  }
}
