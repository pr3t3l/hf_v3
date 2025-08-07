// lib/features/authentication/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/common/models/user_profile.dart';

// Provider for the authentication service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to observe the user's authentication state
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Method to register a new user with email, password, first name, and last name
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Update Firebase Auth profile with displayName
        await user.updateDisplayName('$firstName $lastName');

        // Create initial UserProfile data for Firestore
        final userProfile = UserProfile.initial(
          userId: user.uid,
          email: user.email ?? '',
          firstName: firstName,
          lastName: lastName,
        );

        // Save additional user information in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userProfile.toFirestore());
      }
      return user;
    } on FirebaseAuthException {
      rethrow; // Re-throw for UI to handle
    } catch (_) {
      rethrow;
    }
  }

  // Method to sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Update last login date in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': Timestamp.now(),
        });
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  // Method to send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  // Method to sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      rethrow;
    }
  }

  // Method to get the current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
