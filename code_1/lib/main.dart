// main dart just sends to the homescreen UI
// sets the theme and calls the homescreen class
// starting point is homescreen and everything after that will be in the home screen
// This is what starts it all

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import generated options
// import 'app.dart'; // REMOVE THIS LINE - app.dart doesn't exist
import 'screens/home_screen.dart'; // Import the HomeScreen

void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp( // Initialize Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Your main App widget defined below
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Relief Platform',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'ComicSans',
      ),
      // Assuming HomeScreen is your initial screen
      home: const HomeScreen(),
      // Define routes if you navigate by name
      // routes: {
      //   '/home': (context) => const HomeScreen(),
      //   '/profile': (context) => const SignUpScreen(), // Example route
      //   // Add other routes...
      // },
    );
  }
}




