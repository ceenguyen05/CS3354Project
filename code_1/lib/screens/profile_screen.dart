import 'package:flutter/material.dart';
// Removed direct FirebaseAuth import, use AuthService
import '../services/auth_service.dart';
import '../models/user.dart'; // Import the User model

// Assuming this screen handles both Sign Up and Sign In
class AuthScreen extends StatefulWidget { // Renamed for clarity
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true; // Toggle between Login and Sign Up
  String _email = '';
  String _password = '';
  String _name = ''; // For Sign Up
  String _userType = 'donor'; // Default user type for Sign Up
  bool _isLoading = false;
  String? _errorMessage;

  // Store user data after login/signup
  User? _userData; // Change type to User

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes to update UI automatically on login/logout
    _authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null && _userData != null) {
        // If Firebase user is null (logged out), clear local user data
        setState(() {
          _userData = null;
        });
      }
      // We fetch profile data *after* explicit login/signup via _submitAuthForm
      // Avoid auto-fetching here unless you implement secure token refresh/backend calls
    });
    // Check if already logged in on startup (optional)
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
       print("User already logged in via Firebase: ${currentUser.uid}. Fetching profile...");
       // Attempt to fetch profile - requires secure way to call backend or re-auth
       // For now, we'll rely on explicit login via the form.
       // _fetchProfileOnStartup(currentUser.email!); // Needs secure implementation
    }
  }

  // // Placeholder for fetching profile securely on startup (requires token auth ideally)
  // Future<void> _fetchProfileOnStartup(String email) async { ... }

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      User result; // Change type to User
      if (_isLogin) {
        print('Attempting sign in via AuthService for $_email');
        result = await _authService.signIn(_email, _password); // Assign User directly
        print('Sign in successful via AuthService, user data: ${result.toJson()}'); // Example: Log user data
      } else {
        print('Attempting sign up via AuthService for $_email as $_userType');
        result = await _authService.signUp(_email, _password, _name, _userType); // Assign User directly
        print('Sign up successful via AuthService, user data: ${result.toJson()}'); // Example: Log user data
      }
      setState(() {
        _userData = result; // Store User object
        // Optionally navigate away after success
        // Navigator.of(context).pushReplacementNamed('/home');
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', ''); // Show error
      });
      print('Auth form submission error: $e');
    } finally {
      // Ensure isLoading is reset even if mounted check is needed in complex scenarios
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show profile view if logged in, otherwise show auth form
    return _userData != null ? _buildProfileView() : _buildAuthForm();
  }

  // --- Authentication Form Widget ---
  Widget _buildAuthForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: Colors.cyan[100], // Example styling
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (!_isLogin) // Name field only for Sign Up
                  TextFormField(
                    key: const ValueKey('name'),
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                    onSaved: (value) => _name = value!,
                  ),
                TextFormField(
                  key: const ValueKey('email'),
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
                  onSaved: (value) => _email = value!,
                ),
                TextFormField(
                  key: const ValueKey('password'),
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                  onSaved: (value) => _password = value!,
                ),
                 if (!_isLogin) // User type selection only for Sign Up
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: DropdownButtonFormField<String>(
                        value: _userType,
                        decoration: const InputDecoration(labelText: 'Register As', border: OutlineInputBorder()),
                        items: <String>['donor', 'volunteer', 'organization'] // Match backend/profile needs
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value[0].toUpperCase() + value.substring(1)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) => setState(() => _userType = newValue!),
                        onSaved: (value) => _userType = value!,
                      ),
                    ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16)
                    ),
                    onPressed: _submitAuthForm,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null; // Clear error on switch
                      _formKey.currentState?.reset(); // Reset form fields on switch
                    });
                  },
                  child: Text(
                      _isLogin ? 'Create new account' : 'I already have an account',
                      style: TextStyle(color: Colors.cyan[800]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Profile View Widget (Displayed after login) ---
   Widget _buildProfileView() {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Profile'),
         backgroundColor: Colors.cyan[100],
         actions: [
           IconButton(
             icon: const Icon(Icons.logout),
             tooltip: 'Logout',
             onPressed: () async {
               await _authService.signOut();
               // No need to setState here, the authStateChanges listener handles it
             },
           ),
         ],
       ),
       body: Padding(
         padding: const EdgeInsets.all(16.0),
         child: RefreshIndicator( // Optional: Allow pull-to-refresh profile
           onRefresh: () async {
              // Re-fetch profile data if needed (requires secure backend call)
              print("Profile refresh not implemented (requires secure backend call)");
           },
           child: ListView(
             children: [
               // Use correct field name 'name' (verify in User model)
               Text('Welcome, ${_userData?.name ?? 'User'}!', style: Theme.of(context).textTheme.headlineSmall),
               const SizedBox(height: 15),
               Card(
                 child: Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Use correct field name 'email' (verify in User model)
                       Text('Email: ${_userData?.email ?? 'N/A'}'),
                       const SizedBox(height: 8),
                       // Use correct field name 'userType' (verify in User model)
                       Text('User Type: ${_userData?.userType ?? 'N/A'}'),
                       const SizedBox(height: 8),
                       // Use correct field name 'uid' (verify in User model)
                       Text('UID: ${_userData?.uid ?? 'N/A'}'),
                     ],
                   ),
                 ),
               ),
               // Add more profile details or actions here
             ],
           ),
         ),
       ),
     );
   }
}
