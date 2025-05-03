// Home Screen UI
// This is the first screen the user sees when they enter the website.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- ADD THIS IMPORT
import 'package:code_1/widgets/centered_view.dart';
import 'resource_inventory_screen.dart';
import 'emergency_alerts_screen.dart';
import 'donation_screen.dart';
import 'request_posting_screen.dart';
import 'package:code_1/navbar/nav_bar.dart';
import '../widgets/intro.dart'; // Correct import for Intro class
import '../widgets/intro2.dart'; // Correct import for Intro2 class
import '../widgets/user_stories.dart';
import '../widgets/explanation.dart';
import '../widgets/contact.dart'; // Correct import for ContactInfoWidget class
import '../widgets/social.dart';
import '../widgets/team.dart';
import '../widgets/ai.dart';

// Import the Volunteer model and service
import '../models/volunteer.dart';
import '../services/volunteer_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Instantiate the VolunteerService
  final VolunteerService _volunteerService = VolunteerService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Build method with Volunteer List ADDED and const fixes ---
    return Scaffold(
      body: Container(
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
        child: SingleChildScrollView( // Ensures content is scrollable
          child: CenteredView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- EXISTING WIDGETS (UNCHANGED) ---
                const CustomNavigationBar(),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30), // Keep existing padding
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18.0, // Keep existing spacing
                      runSpacing: 18.0, // Keep existing runSpacing
                      children: [
                        _animatedButton(
                          label: 'See Available Resource Inventory',
                          page: const ResourceInventoryScreen(),
                        ),
                        _animatedButton(
                          label: 'See Emergency Alerts',
                          page: const EmergencyAlertsScreen(),
                        ),
                        _animatedButton(
                          label: 'Request for Help',
                          page: const RequestPostingScreen(),
                        ),
                        _animatedButton(
                          label: 'Donate Now!',
                          page: const DonationScreen(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // --- END EXISTING WIDGETS ---

                // --- NEW: Volunteer List Section ---
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column( // Wrap title and list in a Column
                    children: [
                      const Text(
                        'Volunteer Status', // Section Title
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      _buildVolunteerList(), // Use StreamBuilder to build the list
                    ],
                  ),
                ),
                const SizedBox(height: 30), // Spacing after volunteer list
                // --- END NEW Volunteer List Section ---


                // --- EXISTING WIDGETS (with const fixes) ---
                FadeTransition(
                  opacity: _fadeAnimation,
                  // REMOVED const from Row and children list
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [ // Keep const on children list IF children are const
                      Expanded(child: Intro()),   // Intro() is likely not const
                      Expanded(child: Intro2()),  // Intro2() is likely not const
                    ],
                  ),
                ),
                const SizedBox(height: 120),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const UserStoriesWidget(), // Assuming this widget CAN be const
                ),
                const SizedBox(height: 120),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const ExplanationWidget(), // Assuming this widget CAN be const
                ),
                 const SizedBox(height: 120),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const AIWidget(), // Assuming this widget CAN be const
                ),
                const SizedBox(height: 120),
                // Updated Row with Social and Team Widgets wrapped in a Wrap widget
                FadeTransition(
                  opacity: _fadeAnimation,
                  // REMOVED const from Wrap and children list
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 22.0, // Space between widgets
                    runSpacing: 22.0, // Space between rows
                    children: [ // REMOVED const from this list
                      Flexible(
                        child: SocialWidget(),  // Left Widget (SocialWidget) - likely not const
                      ),
                      Flexible(
                        child: ContactInfoWidget(),  // Middle Widget (ContactInfoWidget) - likely not const
                      ),
                      Flexible(
                        child: TeamWidget(),  // Right Widget (TeamWidget) - likely not const
                      ),
                    ],
                  ),
                ),
                 const SizedBox(height: 50), // Footer spacing
                // --- END EXISTING WIDGETS ---
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- EXISTING HELPER WIDGET (UNCHANGED) ---
  Widget _animatedButton({required String label, required Widget page}) {
     return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => page,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 30,
        ),
        // Add other styling if needed from your original code
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
  // --- END EXISTING HELPER WIDGET ---


  // --- UPDATED HELPER WIDGET: Builds the volunteer list with refined error handling ---
  Widget _buildVolunteerList() {
    return StreamBuilder<List<Volunteer>>(
      stream: _volunteerService.watchVolunteers(), // Get the stream from the service
      builder: (context, snapshot) {
        // --- Check for errors FIRST ---
        if (snapshot.hasError) {
          print("StreamBuilder Error (Volunteers): ${snapshot.error}"); // Log the specific error object
          String errorMessage = 'An error occurred loading volunteers.';
          // Try to check if it's a FirebaseException (NOW THIS WILL WORK)
          if (snapshot.error is FirebaseException) {
             final fbError = snapshot.error as FirebaseException;
             print("FirebaseException Code: ${fbError.code}");
             print("FirebaseException Message: ${fbError.message}");
             errorMessage = 'Error: ${fbError.message ?? fbError.code}';
          } else {
             // Print the runtime type if it's not a FirebaseException
             print("Error type: ${snapshot.error.runtimeType}");
          }
          // Display a user-friendly message
          return Center(child: Text('$errorMessage\nCheck browser console for more details.'));
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle no data state (stream is active but Firestore returned nothing OR permissions denied silently)
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("StreamBuilder (Volunteers): No data received. Check Firestore data and rules.");
          return const Center(child: Text('No volunteers found.'));
        }

        // If data is available, build the list
        final volunteers = snapshot.data!;
        return Container(
          constraints: const BoxConstraints(maxHeight: 300), // Limit height
          decoration: BoxDecoration( // Optional: Add background/border
             color: Colors.white.withOpacity(0.5),
             borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true, // Important inside Column/constrained height
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              final volunteer = volunteers[index];
              return Card( // Use Card for better visual separation
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                color: Colors.white.withOpacity(0.8), // Semi-transparent card
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(volunteer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Skills: ${volunteer.skills.join(', ')}'),
                  trailing: Icon(
                    volunteer.availability ? Icons.check_circle : Icons.cancel,
                    color: volunteer.availability ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  // --- END UPDATED HELPER WIDGET ---
}
