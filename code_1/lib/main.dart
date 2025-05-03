import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import the generated Firebase options
import 'screens/home_screen.dart'; // Import the HomeScreen

// Make main async
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Relief Platform',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        // Consider using a more standard font unless Comic Sans is required
        fontFamily: 'ComicSans',
        visualDensity: VisualDensity.adaptivePlatformDensity, // Good practice
      ),
      home: const HomeScreen(),
    );
  }
}




