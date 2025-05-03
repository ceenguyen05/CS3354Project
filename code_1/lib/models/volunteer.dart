import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String name;
  final List<String> skills;
  final bool availability;
  final double latitude;
  final double longitude;

  Volunteer({
    required this.id,
    required this.name,
    required this.skills,
    required this.availability,
    required this.latitude,
    required this.longitude,
  });

  // Factory constructor to create a Volunteer instance from Firestore data
  factory Volunteer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final d = snapshot.data();
    if (d == null) {
      throw StateError('Missing data for Volunteer ${snapshot.id}');
    }

    // Handle location map
    double lat = 0.0; // Default values
    double lon = 0.0;
    if (d['location'] is Map) {
      final locationMap = d['location'] as Map<String, dynamic>;
      // Use safe casting and provide default if null
      lat = (locationMap['latitude'] as num?)?.toDouble() ?? 0.0;
      lon = (locationMap['longitude'] as num?)?.toDouble() ?? 0.0;
    } else if (d['latitude'] is num && d['longitude'] is num) {
      // Optional: Handle case where lat/lon are direct fields (if data format changes)
       lat = (d['latitude'] as num).toDouble();
       lon = (d['longitude'] as num).toDouble();
    }


    return Volunteer(
      id: snapshot.id,
      name: d['name'] as String? ?? 'Unknown Name', // Provide default
      skills: List<String>.from(d['skills'] ?? []), // Handle potential null skills list
      availability: d['availability'] as bool? ?? false, // Handle potential null availability
      latitude: lat,   // Assign parsed latitude
      longitude: lon,  // Assign parsed longitude
    );
  }

  // Method to convert a Volunteer instance to a map for Firestore
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'skills': skills,
    'availability': availability,
    'location': { // Write location as a map consistent with python script
      'latitude': latitude,
      'longitude': longitude,
    },
     // Note: We don't usually include the ID in the document data itself
  };
}