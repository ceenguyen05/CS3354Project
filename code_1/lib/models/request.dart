// lib/models/request.dart


// written by: Casey 
// tested by: Casey 
// debugged by: Casey 

import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String name;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Request({
    this.id = '',
    required this.name,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Existing JSON constructor left intact for offline/testing.
  factory Request.fromJson(Map<String, dynamic> json) => Request(
    name: json['name'],
    type: json['type'],
    description: json['description'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.now(),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Firestore ▶️ model
  factory Request.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Request(
      id: doc.id,
      name: data['name'] as String,
      type: data['type'] as String,
      description: data['description'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': Timestamp.now(),
  };
}
