// lib/models/donation.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String name;
  final String type;
  final String detail;
  final DateTime timestamp;

  Donation({
    this.id = '',
    required this.name,
    required this.type,
    required this.detail,
    required this.timestamp,
  });

  /// Offline/testing JSON constructor left intact.
  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
    name: json['name'],
    type: json['type'],
    detail: json['detail'],
    timestamp: DateTime.now(),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'detail': detail,
  };

  /// Firestore ▶️ model
  factory Donation.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return Donation(
      id: doc.id,
      name: d['name'] as String,
      type: d['type'] as String,
      detail: d['detail'] as String,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'detail': detail,
    'timestamp': Timestamp.now(),
  };
}
