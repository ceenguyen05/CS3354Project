// lib/services/donation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/donation.dart';
import 'api.dart'; // <--- Make sure this line exists
import 'package:flutter/foundation.dart'; // Import for debugPrint

class DonationService {
  static Future<List<Donation>> fetchDonations() async {
    final url = Uri.parse('$apiUrl/donations'); // Use apiUrl
    debugPrint('Fetching donations from: $url'); // Log URL
    try {
      final response = await http.get(url);
      debugPrint('Fetch Donations Status: ${response.statusCode}'); // Log status
      debugPrint('Fetch Donations Body: ${response.body}'); // Log body
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Donation.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load donations (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error fetching donations: $e'); // Log error
      throw Exception('Error fetching donations: $e');
    }
  }

  static Future<void> submitDonation(Donation donation) async {
    final url = Uri.parse('$apiUrl/donations'); // Use apiUrl
    final body = jsonEncode(donation.toJson());
    debugPrint('Submitting donation to: $url'); // Log URL
    debugPrint('Submitting donation body: $body'); // Log body
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint('Submit Donation Status: ${response.statusCode}'); // Log status
      debugPrint('Submit Donation Response: ${response.body}'); // Log response
      if (response.statusCode != 200 && response.statusCode != 201) { // Allow 200 OK or 201 Created
        throw Exception('Failed to submit donation (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Error submitting donation: $e'); // Log error
      throw Exception('Error submitting donation: $e');
    }
  }
}

