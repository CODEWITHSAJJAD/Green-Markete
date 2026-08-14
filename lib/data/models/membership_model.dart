class MembershipModel {
  final String businessId;
  final String role;
  final String? accessLevel;
  final bool isClaimed;
  final bool manageOtherSide;

  MembershipModel({
    required this.businessId,
    this.role = 'partner',
    this.accessLevel,
    this.isClaimed = false,
    this.manageOtherSide = false,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      businessId: json['business_id'] as String? ?? '',
      role: json['role'] as String? ?? 'partner',
      accessLevel: json['access_level'] as String?,
      isClaimed: json['is_claimed'] as bool? ?? json['user_id'] != null,
      manageOtherSide: json['manage_other_side'] as bool? ?? false,
    );
  }

  bool get isOwner => role == 'owner' || accessLevel == 'owner';

  /// The side this partner operates on in this business:
  /// `purchaser` | `seller` | `both` | `accountant`.
  String get sideRole {
    if (isOwner || role == 'both' || role == 'partner') return 'both';
    if (role == 'purchaser') return 'purchaser';
    if (role == 'seller') return 'seller';
    if (role == 'accountant') return 'accountant';
    return 'both';
  }

  /// Effective access role used by CapabilityService:
  /// `owner` | `editor` | `viewer` | `accountant`.
  String get effectiveAccessRole {
    if (isOwner) return 'owner';
    if (accessLevel == 'editor') return 'editor';
    if (accessLevel == 'viewer') return 'viewer';
    if (role == 'accountant') return 'accountant';
    if (accessLevel != null && accessLevel!.isNotEmpty) return accessLevel!;
    return 'viewer';
  }
}
