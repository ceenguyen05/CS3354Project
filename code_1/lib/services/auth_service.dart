// lib/services/auth_service.dart
// written by: Casey 
// tested by: Casey 
// debugged by: Casey 

import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Use prefix for firebase auth User
import '../models/user.dart' as app_user; // Use prefix for your User model

class AuthService {
  final _auth = fb_auth.FirebaseAuth.instance;

  /// Sign up user with FirebaseAuth; returns true on success.
  Future<bool> signUp(app_user.User user) async {
    // Use app_user.User
    try {
      await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      return true;
    } on fb_auth.FirebaseAuthException {
      // Use fb_auth prefix
      return false;
    }
  }

  /// Sign in existing user; returns true on success.
  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on fb_auth.FirebaseAuthException {
      // Use fb_auth prefix
      return false;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() => _auth.signOut();

  /// Currently signed-in user (or null).
  fb_auth.User? get currentUser => _auth.currentUser; // Use fb_auth.User
}
