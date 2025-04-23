// sets the model for the user auth system
// takes an email and password 
// also converts user data that has been stored 
// this is good for the database and local data storage 
class User {
  final String email;
  final String password;
  final String displayName;

  User({
    required this.email,
    required this.password,
    this.displayName = '',
  });

  // Convert User to JSON format
  Map<String, dynamic> toJson() {
    final data = {
      'email': email,
      'password': password,
    };
    if (displayName.isNotEmpty) {
      data['display_name'] = displayName;
    }
    return data;
  }

  // Convert JSON to User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      password: json['password'],
      displayName: json['display_name'] ?? '',
    );
  }
}
