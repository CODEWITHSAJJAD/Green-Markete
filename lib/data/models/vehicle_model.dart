class VehicleModel {
  final String id;
  final String businessId;
  final String plateNumber;
  final String? driverName;
  final String? driverPhone;
  final double? capacityValue;
  final String? capacityUnit;
  final String? notes;

  VehicleModel({
    required this.id,
    required this.businessId,
    required this.plateNumber,
    this.driverName,
    this.driverPhone,
    this.capacityValue,
    this.capacityUnit,
    this.notes,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      plateNumber: json['plate_number'] as String,
      driverName: json['driver_name'] as String? ?? json['driverName'] as String?,
      driverPhone: json['driver_phone'] as String? ?? json['driverPhone'] as String?,
      capacityValue: (json['capacity_value'] as num?)?.toDouble(),
      capacityUnit: json['capacity_unit'] as String? ?? json['capacityUnit'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'plate_number': plateNumber,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'capacity_value': capacityValue,
    'capacity_unit': capacityUnit,
    'notes': notes,
  };
}
