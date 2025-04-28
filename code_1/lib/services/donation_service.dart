import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/donation.dart'; // Your Donation model

class DonationService {
  // *** IMPORTANT: Use correct IP and Port 8001 ***
  final String _backendUrl = 'http://localhost:8001'; // Or your actual backend URL

  // Fetch donations from backend
  Future<List<Donation>> fetchDonations() async {
    try {
      // WARNING: Unauthenticated call. Add Auth header if backend secured later.
      final response = await http.get(Uri.parse('$_backendUrl/donations'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Ensure backend response fields match Donation.fromJson expectations
        // Backend GET /donations maps fields to name, type, detail
        return data.map((json) => Donation.fromJson(json)).toList();
      } else {
        print('Failed to load donations: ${response.statusCode}');
        throw Exception('Failed to load donations');
      }
    } catch (e) {
      print('Error fetching donations: $e');
      throw Exception('Error fetching donations: $e');
    }
  }

  // Add a non-monetary donation via backend
  Future<Donation> addNonMonetaryDonation(String name, String type, String detail) async {
     try {
        // WARNING: Unauthenticated call. Add Auth header if backend secured later.
        final headers = {'Content-Type': 'application/json'};
        // Backend POST /donations expects 'name', 'type', 'detail' based on modifications
        final body = jsonEncode({
          'name': name, // Corresponds to itemDescription in backend logic
          'type': type, // Corresponds to donation_type
          'detail': detail // Used by backend to try and parse quantity/value
        });

        print("Adding donation to backend: $body");
        final response = await http.post(
          Uri.parse('$_backendUrl/donations'),
          headers: headers,
          body: body,
        );

        print("Backend /donations POST response: ${response.statusCode}");
        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          print("Donation added successfully: $responseData");
          // Backend maps response back to name, type, detail
          return Donation.fromJson(responseData);
        } else {
          print('Failed to add donation: ${response.statusCode} ${response.body}');
          throw Exception('Failed to add donation');
        }
     } catch (e) {
        print('Error adding donation: $e');
        throw Exception('Error adding donation: $e');
     }
  }

  // Method to create a new donation
  Future<void> createDonation(Donation donation) async {
    final url = Uri.parse('$_backendUrl/donations'); // POST endpoint
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(donation.toJson()), // Use toJson from your Donation model
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Donation created successfully
        print('Donation created successfully');
      } else {
        // Handle error response
        print('Failed to create donation: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create donation: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error creating donation: $e');
      throw Exception('Error creating donation: $e');
    }
  }

  // --- Monetary Donations ---
  // The current backend doesn't support creating Stripe sessions.
  // If you implement Stripe endpoints (e.g., /create-checkout-session) on the backend,
  // you would add a method here to call that endpoint.
  // Future<String> createStripeCheckoutSession( /* donation details */ ) async { ... }
}

