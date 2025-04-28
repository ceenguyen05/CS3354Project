// this file and model screen "models" how the data should be read from the user and stored as a json file in the local database 
// takes the alert title, description and the date of the emergency alert 
// returns an Aert Object with these 3 things 
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp

class Alert {
  final String id; // Add id field
  final String title;
  final String message;
  final String severity;
  final String? targetArea; // Make optional if not always present
  final Timestamp createdAt; // Use Timestamp

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.targetArea,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String, // Expect 'id' from backend
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      targetArea: json['target_area'] as String?, // Match backend field name
      // Handle potential Timestamp conversion if backend sends string
      createdAt: json['createdAt'] is Timestamp
          ? json['createdAt'] as Timestamp
          : Timestamp.now(), // Or parse from string if backend sends string
    );
  }

   // Optional: toJson if you need to send Alert objects
   Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity,
        'target_area': targetArea,
        'createdAt': createdAt,
      };
}
