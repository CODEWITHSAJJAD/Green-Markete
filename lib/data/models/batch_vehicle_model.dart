class BatchVehicleModel {
  final String id;
  final String batchId;
  final String vehicleId;
  final String? vehiclePlateNumber;
  final String? driverName;
  final String? packingRecordId;
  final String? packingLabel;
  final double unitCount;
  final String costType;
  final double transportCost;
  final String? loadDate;
  final String? notes;

  BatchVehicleModel({
    required this.id,
    required this.batchId,
    required this.vehicleId,
    this.vehiclePlateNumber,
    this.driverName,
    this.packingRecordId,
    this.packingLabel,
    this.unitCount = 0,
    this.costType = 'per_vehicle',
    this.transportCost = 0,
    this.loadDate,
    this.notes,
  });

  double get totalCost => costType == 'per_packing'
      ? unitCount * transportCost
      : transportCost;

  factory BatchVehicleModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicles'];
    String? plate;
    String? driver;
    if (vehicle is Map<String, dynamic>) {
      plate = vehicle['plate_number'] as String?;
      driver = vehicle['driver_name'] as String?;
    }
    return BatchVehicleModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      vehiclePlateNumber: plate ?? json['vehicle_plate_number'] as String?,
      driverName: driver ?? json['driver_name'] as String?,
      packingRecordId: json['packing_record_id'] as String?,
      packingLabel: json['packing_label'] as String?,
      unitCount: (json['unit_count'] as num?)?.toDouble() ?? 0,
      costType: json['cost_type'] as String? ?? 'per_vehicle',
      transportCost: (json['transport_cost'] as num?)?.toDouble() ?? 0,
      loadDate: json['load_date'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
