import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/request.dart'; // Your Request model

class RequestPostingService {
  // *** IMPORTANT: Replace with your actual backend URL and Port ***
  final String _backendUrl = 'http://localhost:8001'; // CHANGE THIS

  // Fetch requests from backend
  Future<List<Request>> fetchCurrentRequests() async {
    try {
      // WARNING: Unauthenticated call. Add Auth header if backend secured.
      final response = await http.get(Uri.parse('$_backendUrl/requests'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Ensure backend response fields match Request.fromJson expectations
        // Backend maps 'title' to 'name' in GET /requests response.
        return data.map((json) => Request.fromJson(json)).toList();
      } else {
        print('Failed to load requests: ${response.statusCode}');
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      print('Error fetching requests: $e');
      throw Exception('Error fetching requests: $e');
    }
  }

  // Submit a request via backend
  Future<Request> submitRequest(Request request) async {
     try {
      // WARNING: Unauthenticated call. Add Auth header if backend secured.
      final headers = {'Content-Type': 'application/json'};

      // Convert Request object to JSON. Ensure toJson matches backend expectations.
      // Backend POST /requests expects 'name', 'type', 'description', etc.
      final body = jsonEncode(request.toJson());

      print("Submitting request to backend: $body");

      final response = await http.post(
        Uri.parse('$_backendUrl/requests'),
        headers: headers,
        body: body,
      );

      print("Backend /requests POST response: ${response.statusCode}");
      if (response.statusCode == 201) {
        // Backend returns the created request (potentially with matches)
        final responseData = jsonDecode(response.body);
        print("Request created successfully: $responseData");
        // Ensure backend response can be parsed by Request.fromJson
        // Backend maps 'title' back to 'name' in the response.
        return Request.fromJson(responseData);
      } else {
         print('Failed to submit request: ${response.statusCode} ${response.body}');
        throw Exception('Failed to submit request');
      }
    } catch (e) {
       print('Error submitting request: $e');
      throw Exception('Error submitting request: $e');
    }
  }
}










