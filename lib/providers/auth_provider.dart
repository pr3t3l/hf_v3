// lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/services/auth_service.dart'; // Updated path

// Provider that exposes the user's authentication state (User? or null)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// You can also expose the current user's UID directly if needed
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid;
});
