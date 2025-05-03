// lib/services/resource_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource.dart';

class ResourceService {
  final _col = FirebaseFirestore.instance.collection('resources');

  Stream<List<Resource>> watchResources() {
    return _col
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Resource.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addResource(Resource r) {
    return _col.add(r.toFirestore());
  }
}
