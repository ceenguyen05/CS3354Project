// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Import with prefix
import '../models/user.dart'; // Assuming you have a local User model for profile data

class AuthService {
  final String _backendUrl = 'http://localhost:8001'; // CHANGE THIS
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance; // Use prefix

  // Stream for auth state changes (Firebase User)
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges(); // Use prefix

  // Get current Firebase User
  firebase_auth.User? getCurrentUser() { // Use prefix
    return _firebaseAuth.currentUser;
  }

  // Sign Up (using backend)
  Future<User> signUp(String email, String password, String name, String userType) async {
    final url = Uri.parse('$_backendUrl/signup'); // Corrected endpoint
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'userType': userType,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) { // Check for success codes
        final responseData = jsonDecode(response.body);
        print('Signup Response Body: $responseData'); // Log the response

        // Ensure responseData contains necessary fields before creating User
        if (responseData['uid'] != null) {
           // Correctly create User object from response data
           // Assumes User constructor is: User({required String uid, required String email, String? name, String? userType})
           return User(
             uid: responseData['uid'],         // Use uid from response
             email: responseData['email'] ?? email, // Use email from response or input
             name: responseData['name'],        // Use name from response
             userType: responseData['userType'] // Use userType from response
             // DO NOT pass password here
           );
        } else {
           throw Exception('Signup response missing UID.');
        }
      } else {
        // Attempt to parse error message from backend
        String errorMessage = 'Failed to sign up';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
             errorMessage = errorData['error'];
          }
        } catch (_) {
          // Ignore parsing error, use default message
        }
         print('Signup failed: ${response.statusCode} - ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Signup network or parsing error: $e');
      // Rethrow or handle specific exceptions
      throw Exception('An error occurred during sign up: ${e.toString()}');
    }
  }

  // Sign In (using backend)
  Future<User> signIn(String email, String password) async {
     final url = Uri.parse('$_backendUrl/signin'); // Corrected endpoint
     try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

         if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
             print('Signin Response Body: $responseData'); // Log the response
             // Ensure responseData contains necessary fields
             if (responseData['uid'] != null) {
                // Correctly create User object from response data
                // Assumes User constructor is: User({required String uid, required String email, String? name, String? userType})
                return User(
                  uid: responseData['uid'],         // Use uid from response
                  email: responseData['email'] ?? email, // Use email from response or input
                  name: responseData['name'],        // Use name from response
                  userType: responseData['userType'] // Use userType from response
                  // DO NOT pass password here
                );
             } else {
                throw Exception('Signin response missing UID.');
             }
         } else {
             // Attempt to parse error message
             String errorMessage = 'Failed to sign in';
             try {
               final errorData = jsonDecode(response.body);
               if (errorData['message'] != null) {
                 errorMessage = errorData['message'];
               } else if (errorData['error'] != null) {
                  errorMessage = errorData['error'];
               }
             } catch (_) {}
              print('Signin failed: ${response.statusCode} - ${response.body}');
             throw Exception(errorMessage);
         }
     } catch (e) {
       print('Signin network or parsing error: $e');
       throw Exception('An error occurred during sign in: ${e.toString()}');
     }
  }

  // Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Optionally notify backend if needed
  }

  // Fetch User Profile (Example - if needed separately)
  Future<User> fetchUserProfile(String uid) async { // Use local User model
    // This might require a dedicated backend endpoint like /users/{uid}
    // Or, if signin returns all needed data, this might not be necessary
    throw UnimplementedError("fetchUserProfile not implemented");
  }
}
