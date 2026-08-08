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
    this.totalPackingCost = 0,
  });

  factory PackingRecordModel.fromJson(Map<String, dynamic> json) {
    return PackingRecordModel(
      id: json['id'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? json['batchId'] as String? ?? '',
      unitType: json['unit_type_label'] as String? ??
          json['unit_type'] as String? ??
          json['unitType'] as String? ??
          '',
      unitLabel: json['unit_label'] as String? ?? json['unitLabel'] as String?,
      unitCount: (json['unit_count'] as int?) ?? (json['unitCount'] as int?) ?? 0,
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? (json['costPerUnit'] as num?)?.toDouble() ?? 0,
      totalPackingCost: (json['total_packing_cost'] as num?)?.toDouble() ?? (json['totalPackingCost'] as num?)?.toDouble() ?? 0,
    );
  }
}
