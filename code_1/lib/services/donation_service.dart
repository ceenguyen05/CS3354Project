// lib/services/donation_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation.dart';

class DonationService {
  final _col = FirebaseFirestore.instance.collection('donations');

  /// Real-time stream of all donations, newest first.
  Stream<List<Donation>> watchDonations() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Donation.fromFirestore(doc)).toList(),
        );
  }

  /// Add a new donation document.
  Future<void> addDonation(Donation donation) {
    return _col.add(donation.toFirestore());
  }
}
