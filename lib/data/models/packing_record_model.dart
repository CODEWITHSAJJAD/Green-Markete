class PackingRecordModel {
  final String id;
  final String batchId;
  final String unitType;
  final String? unitLabel;
  final int unitCount;
  final double costPerUnit;
  final double totalPackingCost;

  PackingRecordModel({
    required this.id,
    required this.batchId,
    required this.unitType,
    this.unitLabel,
    required this.unitCount,
    required this.costPerUnit,
    required this.totalPackingCost,
  });

  factory PackingRecordModel.fromJson(Map<String, dynamic> json) {
    return PackingRecordModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      unitType: json['unit_type'] as String,
      unitLabel: json['unit_label'] as String?,
      unitCount: json['unit_count'] as int,
      costPerUnit: (json['cost_per_unit'] as num).toDouble(),
      totalPackingCost: (json['total_packing_cost'] as num?)?.toDouble() ??
          (json['unit_count'] as int) * (json['cost_per_unit'] as num).toDouble(),
    );
  }
}
