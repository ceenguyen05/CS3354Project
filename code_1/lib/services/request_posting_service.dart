// lib/services/request_posting_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request.dart';

class RequestPostingService {
  final _col = FirebaseFirestore.instance.collection('requests');

  /// Real-time stream of all requests, newest first.
  Stream<List<Request>> watchRequests() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Request.fromFirestore(doc)).toList(),
        );
  }

  /// Add a new request document.
  Future<void> submitRequest(Request req) {
    return _col.add(req.toFirestore());
  }
}
