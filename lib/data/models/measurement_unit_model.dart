class MeasurementUnitModel {
  final String id;
  final String businessId;
  final String name;
  final double kgPerUnit;

  MeasurementUnitModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.kgPerUnit,
  });

  factory MeasurementUnitModel.fromJson(Map<String, dynamic> json) {
    return MeasurementUnitModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      kgPerUnit: (json['kg_per_unit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'name': name,
    'kg_per_unit': kgPerUnit,
  };
}
