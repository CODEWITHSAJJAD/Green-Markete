class MarketModel {
  final String id;
  final String businessId;
  final String name;
  final String city;
  final String? address;
  final String? stallNumber;
  final String? marketType;

  MarketModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.city,
    this.address,
    this.stallNumber,
    this.marketType,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      stallNumber: json['stall_number'] as String?,
      marketType: json['market_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'name': name,
    'city': city,
    'address': address,
    'stall_number': stallNumber,
    'market_type': marketType,
  };
}
