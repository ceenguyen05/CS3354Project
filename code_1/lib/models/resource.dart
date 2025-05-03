// lib/models/resource.dart


// written by: Casey 
// tested by: Casey 
// debugged by: Casey 

import 'package:cloud_firestore/cloud_firestore.dart';

class Resource {
  final String id;
  final String name;
  final String location;
  final int quantity;
  final DateTime timestamp;

  Resource({
    this.id = '',
    required this.name,
    required this.location,
    required this.quantity,
    required this.timestamp,
  });

  /// Existing JSON constructor left intact.
  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    name: json['name'],
    location: json['location'],
    quantity: json['quantity'] as int,
    timestamp: DateTime.now(),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'quantity': quantity,
  };

  /// Firestore ▶️ model
  factory Resource.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return Resource(
      id: doc.id,
      name: d['name'] as String,
      location: d['location'] as String,
      quantity: d['quantity'] as int,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'location': location,
    'quantity': quantity,
    'timestamp': Timestamp.now(),
  };
}
