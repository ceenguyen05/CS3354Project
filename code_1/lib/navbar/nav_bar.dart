import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/donation_screen.dart';
import '../screens/emergency_alerts_screen.dart';
import '../screens/profile_screen.dart'; // Correct import for AuthScreen

// Placeholder widget if screens don't exist yet
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title Screen - Not Implemented'));
  }
}

class NavBar extends StatefulWidget {
  const NavBar(); // Constructor without key

  @override
  State<NavBar> createState() => _NavBarState(); // Use modern createState syntax
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Requests Placeholder')), // Simple Placeholder
    const Center(child: Text('Resources Placeholder')), // Simple Placeholder
    const Center(child: Text('Donate Placeholder')),    // Simple Placeholder
    const Center(child: Text('Alerts Placeholder')),   // Simple Placeholder
    const AuthScreen(), // Keep AuthScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Use IndexedStack to preserve state
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Ensure currentIndex is set
        onTap: _onItemTapped,      // Ensure onTap is set
        type: BottomNavigationBarType.fixed, // Ensure type allows more than 3 items to be visible
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page), // Example icon
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory), // Example icon
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism), // Example icon
            label: 'Donate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login), // Changed icon for Auth
            label: 'Login/Sign Up', // Changed label
          ),
        ],
      ),
    );
  }
}
