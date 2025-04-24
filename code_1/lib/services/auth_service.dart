// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart' as app_user; // Use prefix to avoid name clash
import 'api.dart'; // Ensure this import is present
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth User

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign up a new user via backend API (creates both Firebase Auth + Firestore profile).
  // Renamed from signUp to signUpWithBackend
  Future<bool> signUpWithBackend(app_user.User user) async {
    debugPrint('Attempting sign up via backend: ${user.email}');
    final resp = await http.post(
      Uri.parse('$apiUrl/signup'), // Use apiUrl
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    debugPrint('Backend Sign Up Status: ${resp.statusCode}');
    return resp.statusCode == 200 || resp.statusCode == 201; // Allow Created
  }

  /// Sign in by verifying a Firebase ID token via backend; returns the user profile.
  Future<Map<String, dynamic>?> signInWithToken(String idToken) async {
    debugPrint('Attempting sign in via backend with token');
    final resp = await http.post(
      Uri.parse('$apiUrl/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    debugPrint('Backend Sign In (Token) Status: ${resp.statusCode}');
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Sign in using email/password via backend
  Future<bool> signInWithEmailBackend({ // Renamed for clarity
    required String email,
    required String password,
  }) async {
    debugPrint('Attempting sign in via backend with email: $email');
    final resp = await http.post(
      Uri.parse('$apiUrl/signin'), // Use apiUrl
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
     debugPrint('Backend Sign In (Email) Status: ${resp.statusCode}');
    return resp.statusCode == 200;
  }

  /// Sign up directly using Firebase Authentication
  // Kept name as signUp for direct Firebase interaction
  Future<User?> signUp(String email, String password) async {
    debugPrint('Attempting direct Firebase sign up with email: $email'); // Log attempt
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Direct Firebase sign up successful: ${result.user?.uid}'); // Log success
      // Optionally: Call backend here to create user profile in Firestore if needed
      // await createUserProfileInFirestore(result.user);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      // Rethrow or handle specific errors (e.g., display message)
      throw Exception('Sign up failed: ${e.message}'); // Propagate error
    } catch (e) {
      debugPrint('Generic error during direct Firebase sign up: $e'); // Log other errors
       throw Exception('An unknown error occurred during sign up.'); // Propagate error
    }
  }

   /// Sign in directly using Firebase Authentication
  Future<User?> signInWithEmail(String email, String password) async {
    debugPrint('Attempting direct Firebase sign in with email: $email');
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Direct Firebase sign in successful: ${result.user?.uid}');
      // Optionally: Fetch user profile from Firestore/backend after successful sign in
      // final userProfile = await fetchUserProfileFromBackend(result.user?.uid);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      throw Exception('Sign in failed: ${e.message}'); // Propagate error
    } catch (e) {
      debugPrint('Generic error during direct Firebase sign in: $e');
      throw Exception('An unknown error occurred during sign in.'); // Propagate error
    }
  }

  // Add other methods like signOut, currentUser stream etc. if needed
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('User signed out');
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

}
