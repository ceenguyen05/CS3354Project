// lib/services/resource_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resource.dart';
import 'api.dart';

class ResourceService {
  static Future<List<Resource>> fetchResources() async {
    final resp = await http.get(Uri.parse('$apiUrl/resources'));
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((e) => Resource.fromJson(e)).toList();
    }
    throw Exception('Failed to load resources');
  }

  static Future<void> addResource(Resource resource) async {
    final resp = await http.post(
      Uri.parse('$apiUrl/resources'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(resource.toJson()),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to add resource');
    }
  }
}
