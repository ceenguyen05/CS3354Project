// lib/models/resource.dart

class Resource {
  final String name;
  final int quantity;
  final String location;

  Resource({
    required this.name,
    required this.quantity,
    required this.location,
  });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    location: json['location'] as String,
  );

  /// ← Add this so ResourceService can call resource.toJson()
  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'location': location,
  };
}
