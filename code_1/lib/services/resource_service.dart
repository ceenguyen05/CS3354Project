import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resource.dart';

class ResourceService {
  // *** IMPORTANT: Replace with your actual backend URL and Port ***
  final String _backendUrl = 'http://localhost:8001'; // CHANGE THIS

  // Fetch resources from backend
  Future<List<Resource>> fetchResources() async {
    try {
      // WARNING: Unauthenticated call. Add Auth header if backend secured later.
      final response = await http.get(Uri.parse('$_backendUrl/resources'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Ensure backend response fields match Resource.fromJson expectations
        // Backend GET /resources returns name, quantity, description, category, id
        // Frontend model expects name, quantity, location
        // We need to adapt or ignore fields. Let's try to adapt.
        return data.map((json) {
             // Map backend fields to frontend model fields
             return Resource(
                  name: json['name'] ?? 'Unknown',
                  quantity: json['quantity'] ?? 0,
                  // Backend doesn't return location in GET /resources by default.
                  // Use a placeholder or modify backend if location is crucial here.
                  location: json['location'] ?? 'N/A',
                  // You might want to add category/description to your Resource model
                  // category: json['category'],
                  // description: json['description'],
                  // id: json['id'] // Add id to model if needed
             );
        }).toList();
      } else {
        print('Failed to load resources: ${response.statusCode}');
        throw Exception('Failed to load resources');
      }
    } catch (e) {
      print('Error fetching resources: $e');
      throw Exception('Error fetching resources: $e');
    }
  }

  // Add a resource via backend
  Future<Resource> addResource(String name, int quantity, String? description, String? category /*, String location - backend doesn't accept */) async {
     try {
        // WARNING: Unauthenticated call. Add Auth header if backend secured later.
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'name': name,
          'quantity': quantity,
          'description': description, // Send if available
          'category': category,       // Send if available
          // 'location': location, // Backend POST /resources doesn't accept location
        });

        print("Adding resource to backend: $body");
        final response = await http.post(
          Uri.parse('$_backendUrl/resources'),
          headers: headers,
          body: body,
        );

        print("Backend /resources POST response: ${response.statusCode}");
        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          print("Resource added successfully: $responseData");
          // Map response back to frontend model
           return Resource(
                name: responseData['name'] ?? 'Unknown',
                quantity: responseData['quantity'] ?? 0,
                location: responseData['location'] ?? 'N/A', // Backend doesn't return location
                // id: responseData['id'] // Add id to model if needed
           );
        } else {
          print('Failed to add resource: ${response.statusCode} ${response.body}');
          throw Exception('Failed to add resource');
        }
     } catch (e) {
        print('Error adding resource: $e');
        throw Exception('Error adding resource: $e');
     }
  }
}





