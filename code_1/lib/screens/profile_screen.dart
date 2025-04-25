// UI for signup / sign in 
// Creates a basics screen and imports the model and service darts for this specific function
// toggles between sign in and sign out 
// user enters email and password
// not integrated yet for data storage in the backend so user will get an error message after signing in
// will be integrated with database and backend for deliverable 2 
// this screen simply lays the groundwork for user sign in and sign out 

import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Import Firebase Auth
import '../models/user.dart' as app_user;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = true;
  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();  // ← add this
    super.dispose();
  }

  // Email validator
  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Check if email contains '@' and ends with '.com' or '.edu'
    if (!value.contains('@') || (!value.endsWith('.com') && !value.endsWith('.edu'))) {
      return 'Please enter a valid email address (e.g., user@domain.com)';
    }
    return null;
  }

  // Password validator
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 7) {
      return 'Password must be at least 7 characters';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least 1 special character';
    }
    return null;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Show loading indicator (optional but good UX)
    // showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));

    try {
      if (_isSignUp) {
        final newUser = app_user.User(
          email: email,
          password: password, // Sending password here might be insecure depending on backend
          displayName: _displayNameController.text.trim(),
        );
        final success = await _authService.signUpWithBackend(newUser);

        // if (mounted) Navigator.pop(context); // Hide loading indicator

        if (success && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sign Up Successful. Please Sign In.')));
          // Switch to Sign In view after successful signup
          setState(() {
            _isSignUp = false;
          });
        } else if (mounted) { // Check mounted before showing error
           ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sign Up failed on server. Please try again.')));
        }
      } else { // Sign In logic
        // 1) Sign in to Firebase
        // Change the expected type to fb_auth.User?
        final fb_auth.User? firebaseUser = await _authService.signInWithEmail(email, password);

        // Check if the returned firebaseUser is null
        if (firebaseUser == null) {
           // if (mounted) Navigator.pop(context); // Hide loading indicator
           throw Exception('Firebase authentication failed. Check email/password.');
        }

        // Safely get the ID token directly from the Firebase User object
        final String? idToken = await firebaseUser.getIdToken(); // Get token from firebaseUser

        if (idToken == null) {
          throw Exception('Could not retrieve ID token.');
        }

        // 2) Send token to backend for verification/profile retrieval
        final profile = await _authService.signInWithToken(idToken);

        // if (mounted) Navigator.pop(context); // Hide loading indicator

        if (profile != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sign In Successful')));
          // TODO: Navigate to the main app screen after successful sign-in
          // Navigator.pushReplacementNamed(context, '/home'); // Example navigation
        } else if (mounted) { // Check mounted before showing error
           ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Backend sign in failed. Please try again.')));
        }
      }
    } catch (e) {
      // if (mounted) Navigator.pop(context); // Hide loading indicator
      if (mounted) { // Check mounted before showing error
        // Provide more specific error messages if possible
        String errorMessage = 'An error occurred: $e';
        if (e.toString().contains('firebase_auth/invalid-credential') || e.toString().contains('Firebase auth failed')) {
            errorMessage = 'Invalid email or password.';
        } else if (e.toString().contains('firebase_auth/user-not-found')) {
            errorMessage = 'No user found with this email.';
        } else if (e.toString().contains('firebase_auth/wrong-password')) {
            errorMessage = 'Incorrect password.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e, stackTrace) { // Catch everything
        // ONLY PRINT - NO OTHER LOGIC
        print("--- RAW CATCH BLOCK ---");
        print("Caught Error Type: ${e.runtimeType}");
        print("Caught Error: $e");
        print("Caught StackTrace:\n$stackTrace");
        print("--- END RAW CATCH BLOCK ---");
        // DO NOT add ScaffoldMessenger or any other logic here for now
    }
    // Ensure no other 'on Exception catch' or 'on FirebaseAuthException catch' blocks exist below this one.
  } // End of _submit method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp ? 'Sign Up' : 'Sign In',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 26,  // Set font size to 26
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF), // white
                Color(0xFFE0F7FA), // very light blue
                Color(0xFFB2EBF2), // soft sky blue
              ],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF), // white
              Color(0xFFE0F7FA), // very light blue
              Color(0xFFB2EBF2), // soft sky blue
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: _passwordValidator,
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            validator: (value) =>
                                value == null || value.trim().isEmpty ? 'Please enter a display name' : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.black),
                            ),
                          ),
                          child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          },
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign in'
                                : 'Don’t have an account? Sign up',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
