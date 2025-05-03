import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer.dart'; // Import the Volunteer model

class VolunteerService {
  // Reference to the 'volunteers' collection in Firestore
  final CollectionReference<Volunteer> _volunteersRef = FirebaseFirestore.instance
      .collection('volunteers')
      .withConverter<Volunteer>(
        fromFirestore: (snapshot, _) => Volunteer.fromFirestore(snapshot),
        toFirestore: (volunteer, _) => volunteer.toFirestore(),
      );

  /// Provides a real-time stream of all volunteers, ordered by name.
  Stream<List<Volunteer>> watchVolunteers() {
    return _volunteersRef
        .orderBy('name') // Example ordering, adjust if needed
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches all volunteers once.
  Future<List<Volunteer>> getVolunteersOnce() async {
    final snapshot = await _volunteersRef.orderBy('name').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Add other methods if needed, e.g., getVolunteerById(String id)
}