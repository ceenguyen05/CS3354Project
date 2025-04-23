// lib/models/request.dart

/// Model for an aid request.
class Request {
  final String name;
  final String type;
  final String description;
  final double latitude;
  final double longitude;

  Request({
    required this.name,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  /// Convert this Request into JSON to send to your backend.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create a Request instance from JSON coming back from your backend.
  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      name: (json['name'] as String?) ?? 'Unknown',
      type: (json['type'] as String?) ?? 'Unknown',
      description: (json['description'] as String?) ?? '',
      // Handle potential null values for latitude and longitude
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
