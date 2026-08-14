class PartnerModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? city;
  final String role;
  final String? accessLevel;
  final bool isClaimed;
  final bool manageOtherSide;
  final String? businessId;
  final String? userId;

  PartnerModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.city,
    this.role = 'partner',
    this.accessLevel,
    this.isClaimed = false,
    this.manageOtherSide = false,
    this.businessId,
    this.userId,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      role: json['role'] as String? ?? 'partner',
      accessLevel: json['access_level'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? json['user_id'] != null,
      manageOtherSide: json['manage_other_side'] as bool? ?? false,
      businessId: json['business_id'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'city': city,
    'role': role,
    'business_id': businessId,
    if (userId != null) 'user_id': userId,
  };
}
