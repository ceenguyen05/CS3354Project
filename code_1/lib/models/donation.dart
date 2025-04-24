// defines a model for the donation function 
// takes and sets a name, a type of donation either money or a resource, and the the detail (how much or what resource)
// easy access and model for backend integration and local data handling. Also in use with json. 
// All three access points should be useful in either the final integration or during testing 

class Donation {
  final String name;
  final String type;
  final String detail;
  final String? itemName; // Changed from String to String?

  Donation({
    required this.name,
    required this.type,
    required this.detail,
    this.itemName,
  });
  

  /// Deserialize a Donation from JSON.
  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
    name: json['donor_name'] as String? ?? 'Unknown',
    type: json['donation_type'] as String? ?? 'Unknown',
    detail: json['detail'] as String? ?? '',
    itemName: json['item_name'] as String?,
  );

  Map<String, dynamic> toJson() => {
        'donor_name': name, // To this key
        'donation_type': type, // To this key
        'detail': detail,
        // 'itemName': itemName, // Consider if this field is needed by the backend
                                // If not, you might remove it from here too.
                                // If it IS needed, ensure the backend expects 'itemName'.
      };
}


