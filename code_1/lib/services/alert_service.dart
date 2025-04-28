// filepath: code_1/lib/services/alert_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart'; // Make sure you have an Alert model

class AlertService {
  // *** IMPORTANT: Use correct IP and Port 8001 ***
  final String _backendUrl = 'http://localhost:8001'; // CHANGE THIS if needed

  // Fetch alerts from backend
  Future<List<Alert>> fetchAlerts() async {
    try {
      // WARNING: Unauthenticated call. Add Auth header if backend secured later.
      final response = await http.get(Uri.parse('$_backendUrl/alerts'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Ensure backend response fields match Alert.fromJson expectations
        return data.map((json) => Alert.fromJson(json)).toList();
      } else {
        print('Failed to load alerts: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      throw Exception('Error fetching alerts: $e');
    }
  }
}