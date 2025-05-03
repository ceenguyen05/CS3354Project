// lib/services/emergency_alert_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert.dart';

class EmergencyAlertService {
  final _col = FirebaseFirestore.instance.collection('alerts');

  /// Real-time stream of all alerts, newest first.
  Stream<List<Alert>> watchAlerts() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Alert.fromFirestore(doc)).toList(),
        );
  }
}
