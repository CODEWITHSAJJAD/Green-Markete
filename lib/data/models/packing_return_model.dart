class PackingReturnModel {
  final String id;
  final String batchId;
  final String? packingRecordId;
  final String? packingLabel;
  final String? unitType;
  final double quantity;
  final int count;
  final String? returnDate;
  final String? notes;
  final double? costPerUnit;

  PackingReturnModel({
    required this.id,
    required this.batchId,
    this.packingRecordId,
    this.packingLabel,
    this.unitType,
    required this.quantity,
    this.count = 0,
    this.returnDate,
    this.notes,
    this.costPerUnit,
  });

  double get totalReturnCost => (costPerUnit ?? 0) * quantity;

  factory PackingReturnModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? packing;
    final packingRaw = json['packing_records'];
    if (packingRaw is Map<String, dynamic>) {
      packing = packingRaw;
    }
    return PackingReturnModel(
      id: json['id'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? json['batchId'] as String? ?? '',
      packingRecordId: json['packing_record_id'] as String? ??
          json['packingRecordId'] as String?,
      packingLabel: packing?['unit_label'] as String? ??
          packing?['unit_type_label'] as String?,
      unitType: packing?['unit_type_label'] as String? ??
          packing?['unit_type'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as int?) ?? 0,
      returnDate: json['return_date'] as String? ??
          json['returnDate'] as String?,
      notes: json['notes'] as String?,
      costPerUnit: (packing?['cost_per_unit'] as num?)?.toDouble(),
    );
  }
}

class PackingReturnCreate {
  final String packingRecordId;
  final double quantity;
  final int? count;
  final String? returnDate;
  final String? notes;

  PackingReturnCreate({
    required this.packingRecordId,
    required this.quantity,
    this.count,
    this.returnDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'packing_record_id': packingRecordId,
      'quantity': quantity,
      if (count != null && count! > 0) 'count': count,
      if (returnDate != null && returnDate!.isNotEmpty) 'return_date': returnDate,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
