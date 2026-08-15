class PartnerModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? city;
  final String role;
  final String memberType;
  final String? accessLevel;
  final bool isClaimed;
  final bool manageOtherSide;
  final String? businessId;
  final String? userId;
  final Map<String, bool>? permissions;

  PartnerModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.city,
    this.role = 'purchaser',
    this.memberType = 'employee',
    this.accessLevel,
    this.isClaimed = false,
    this.manageOtherSide = false,
    this.businessId,
    this.userId,
    this.permissions,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    Map<String, bool>? parsedPermissions;
    if (json['permissions'] is Map) {
      parsedPermissions = (json['permissions'] as Map).map(
        (k, v) => MapEntry(k.toString(), v == true),
      );
    }

    final rawRole = json['role'] as String? ?? 'purchaser';
    final role = rawRole == 'partner' ? 'both' : rawRole;
    final memberType = json['member_type'] as String? ??
        (rawRole == 'partner' ? 'partner' : 'employee');

    return PartnerModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      role: role,
      memberType: memberType,
      accessLevel: json['access_level'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? json['user_id'] != null,
      manageOtherSide: json['manage_other_side'] as bool? ?? false,
      businessId: json['business_id'] as String?,
      userId: json['user_id'] as String?,
      permissions: parsedPermissions,
    );
  }

  bool get isEmployee => memberType == 'employee' && role != 'owner';
  bool get isPartner => memberType == 'partner' || role == 'owner';

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'city': city,
    'role': role,
    'member_type': memberType,
    'business_id': businessId,
    if (userId != null) 'user_id': userId,
    if (permissions != null) 'permissions': permissions,
  };
}
