// lib/features/authentication/presentation/controllers/auth_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/services/auth_service.dart'; // Updated path

// Provider to handle authentication logic (register, login, logout)
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      return AuthController(ref.read(authServiceProvider));
    });

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthController(this._authService)
    : super(const AsyncValue.data(null)); // Initial state: not authenticated

  Future<void> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    state = const AsyncValue.loading(); // Set loading state
    try {
      final user = await _authService.registerWithEmailAndPassword(
        email,
        password,
        firstName,
        lastName,
      );
      state = AsyncValue.data(user); // Set success state with user data
    } catch (e, st) {
      state = AsyncValue.error(e, st); // Set error state
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null); // Set to null after signing out
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading(); // Could use a different state for this
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(
        null,
      ); // No user change, just operation success
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
