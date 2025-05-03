// lib/models/alert.dart


// written by: Casey 
// tested by: Casey 
// debugged by: Casey 

import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String id;
  final String message;
  final String severity;
  final DateTime timestamp;

  Alert({
    this.id = '',
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  /// Existing JSON constructor left intact.
  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    message: json['message'],
    severity: json['severity'],
    timestamp: DateTime.now(),
  );
  Map<String, dynamic> toJson() => {'message': message, 'severity': severity};

  /// Firestore ▶️ model
  factory Alert.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Alert(
      id: doc.id,
      message: d['message'] as String,
      severity: d['severity'] as String,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
    );
  }
}
