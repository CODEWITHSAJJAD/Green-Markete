class User {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? city;
  final String? role;

  User({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.city,
    this.role,
  });
}
