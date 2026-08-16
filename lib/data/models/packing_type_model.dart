class PackingTypeModel {
  final String id;
  final String businessId;
  final String name;
  final double kgCapacity;

  PackingTypeModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.kgCapacity,
  });

  factory PackingTypeModel.fromJson(Map<String, dynamic> json) {
    return PackingTypeModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      kgCapacity: (json['kg_capacity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'name': name,
    'kg_capacity': kgCapacity,
  };
}
