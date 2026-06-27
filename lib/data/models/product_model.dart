class ProductModel {
  final String id;
  final String businessId;
  final String name;
  final String? category;
  final String baseUnit;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.category,
    this.baseUnit = 'kg',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      baseUnit: json['base_unit'] as String? ?? 'kg',
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'name': name,
    'category': category,
    'base_unit': baseUnit,
  };
}
