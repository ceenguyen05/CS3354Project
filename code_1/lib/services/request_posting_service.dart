// lib/services/request_posting_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/request.dart';
import 'api.dart';

class RequestService {
  // Adjust the URL to your actual backend endpoint
  static const String _baseUrl = 'http://127.0.0.1:8001'; // Or your deployed URL

  static Future<List<Request>> fetchCurrentRequests() async {
    final response = await http.get(Uri.parse('$_baseUrl/requests'));

    if (response.statusCode == 200) {
      // Print the raw response body BEFORE parsing
      print('--- Raw JSON Response from /requests ---');
      print(response.body);
      print('---------------------------------------');

      // Now parse the JSON
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Request.fromJson(json)).toList();
    } else {
      print('Failed to load requests: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load requests');
    }
  }

  static Future<void> submitRequest(Request request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) { // Allow 200 or 201 for success
      print('Failed to submit request: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to submit request: ${response.body}');
    }
     print('Request submitted successfully.'); // Add success log
  }
}
