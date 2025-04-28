// sets the model for the user profile data
// takes uid, email, name, and userType
// this is good for the database and local data storage
class User {
  final String uid; // Added UID
  final String email;
  final String? name; // Made nullable as it might not always be present initially
  final String? userType; // Made nullable

  // Removed password field

  User({
    required this.uid, // Added UID
    required this.email,
    this.name, // Optional
    this.userType, // Optional
    // Removed required password
  });

  // Convert User to JSON format (optional, might not be needed if only receiving)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid, // Added UID
      'email': email,
      'name': name, // Added name
      'userType': userType, // Added userType
      // Removed password
    };
  }

  // Convert JSON to User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String, // Added UID
      email: json['email'] as String,
      name: json['name'] as String?, // Added name (nullable)
      userType: json['userType'] as String?, // Added userType (nullable)
      // Removed password
    );
  }
}
