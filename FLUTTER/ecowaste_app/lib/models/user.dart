class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }
}
