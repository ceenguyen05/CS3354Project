// UI for emergency alerts 
// Creates a basics screen and imports the model and service darts for this specific function
// displays emergency alerts 
// takes in the json data that is preloaded for delieverable 1 
// in deliberable 2, will implemented a rotating emergency alerts that is randomized and displayed 
// will be updated to stay on while emergency is active and for ones that are outdated/ dealt with, will say so

import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/emergency_alert_service.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EmergencyAlertsScreenState createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  late Future<List<Alert>> alerts;

  @override
  void initState() {
    super.initState();
    alerts = EmergencyAlertService.fetchEmergencyAlerts(); // Fetching alerts from local JSON
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 16), // Added space above the title
          child: const Text(
            'Emergency Alerts',
            style: TextStyle(
              fontSize: 26, // Larger text size
              fontWeight: FontWeight.bold, // Make the text bold
              color: Colors.black, // Set text color to black
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Alert>>(
        future: alerts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading data.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No emergency alerts available.'));
          }

          final alertsList = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(
                  alertsList.length,
                  (index) {
                    final alert = alertsList[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFE0F7FA),
                            Color(0xFFB2EBF2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(),
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          alert.alertTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "${alert.alertDescription}\nLocation: ${alert.alertLocation} \nDate: ${alert.alertDate}",
                          style: const TextStyle(fontSize: 14), // Adjust subtitle text size
                          maxLines: 3, // Limit subtitle to 3 lines
                          overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



