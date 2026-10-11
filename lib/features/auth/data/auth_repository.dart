import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final ApiClient _apiClient;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    required ApiClient apiClient,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _apiClient = apiClient;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Upsert user on Spring Boot backend
    await _syncUserWithBackend();
    return cred;
  }

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }

    // Register user on backend
    await _syncUserWithBackend(displayName: displayName);
    return cred;
  }

  Future<void> _syncUserWithBackend({String? displayName}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _apiClient.dio.post(
          ApiConstants.authRegister,
          data: {
            'email': user.email,
            'displayName': displayName ?? user.displayName ?? '',
          },
        );
      }
    } catch (e) {
      // Backend may be offline; it will be synced later
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
