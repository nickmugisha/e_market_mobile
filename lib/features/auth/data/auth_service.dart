import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_authMessage(error));
    } catch (_) {
      throw const AuthFailure(
        'Unable to sign in right now. Check your connection and try again.',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    required String whatsappNumber,
  }) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Firebase did not create the account.');
      }

      await user.updateDisplayName(name.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': user.email ?? email.trim(),
        'phone': phone.trim(),
        'role': role.name,
        'whatsappNumber': role == UserRole.seller
            ? whatsappNumber.trim()
            : '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_authMessage(error));
    } on FirebaseException catch (error) {
      final createdUser = credential?.user;
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Best effort rollback if profile creation fails.
        }
      }
      throw AuthFailure(
        error.code == 'permission-denied'
            ? 'Your account was created, but Firestore blocked the profile. Deploy the e-market security rules and try again.'
            : 'Could not save your profile. Check your connection and try again.',
      );
    } catch (_) {
      final createdUser = credential?.user;
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Best effort rollback if profile creation fails.
        }
      }
      throw const AuthFailure(
        'Unable to create the account right now. Please try again.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final cleanedEmail = email.trim();
    if (cleanedEmail.isEmpty) {
      throw const AuthFailure('Enter your email address first.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: cleanedEmail);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_authMessage(error));
    } catch (_) {
      throw const AuthFailure(
        'Could not send the reset email. Check your connection and try again.',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _authMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'Incorrect email or password.',
      'email-already-in-use' =>
        'An account already exists with this email address.',
      'weak-password' => 'Use a stronger password with at least 6 characters.',
      'too-many-requests' =>
        'Too many attempts. Wait a moment before trying again.',
      'network-request-failed' =>
        'Network error. Check your internet connection and try again.',
      _ => error.message ?? 'Firebase authentication failed. Please try again.',
    };
  }
}
