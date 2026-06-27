class BusinessModel {
  final String id;
  final String name;
  final String ownerId;
  final String businessType;
  final String? createdAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.businessType = 'multi_partner',
    this.createdAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      businessType: json['business_type'] as String? ?? 'multi_partner',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'business_type': businessType,
  };
}
