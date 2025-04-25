// main dart just sends to the homescreen UI 
// sets the theme and calls the homescreen class 
// starting point is homescreen and everything after that will be in the home screen 
// This is what starts it all

import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import the HomeScreen
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import the generated Firebase options

void main() async { // Make main asynchronous
  // Ensure Flutter bindings are initialized (required for Firebase init)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Now run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Relief Web App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'ComicSans', 
      ),
      home: const HomeScreen(), 
    );
  }
}




