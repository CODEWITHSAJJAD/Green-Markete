class UserModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? city;
  final String? role;
  final String? businessId;
  final bool isActive;

  UserModel({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.city,
    this.role,
    this.businessId,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String?,
      role: json['role'] as String?,
      businessId: json['business_id'] as String? ?? json['id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'city': city,
    'role': role,
    'business_id': businessId,
    'is_active': isActive,
  };
}
