class BatchModel {
  final String id;
  final String businessId;
  final String productId;
  final String? productName;
  final String batchCode;
  final String? sourceMarketId;
  final String? destinationMarketId;
  final String purchaseDate;
  final double totalQuantity;
  final String quantityUnit;
  final double purchasePricePerUnit;
  final double totalPurchaseCost;
  final String status;
  final String? transportPaidBy;
  final String? notes;
  final String? supplierName;
  final String? purchasePaymentMode;
  final double purchaseAmountPaid;
  final String? createdAt;
  final String? startDate;
  final String? endDate;
  final double? totalAmount;
  final double? expenseAmount;
  final double? margin;

  BatchModel({
    required this.id,
    required this.businessId,
    required this.productId,
    this.productName,
    required this.batchCode,
    this.sourceMarketId,
    this.destinationMarketId,
    required this.purchaseDate,
    required this.totalQuantity,
    required this.quantityUnit,
    required this.purchasePricePerUnit,
    required this.totalPurchaseCost,
    required this.status,
    this.transportPaidBy,
    this.notes,
    this.supplierName,
    this.purchasePaymentMode,
    this.purchaseAmountPaid = 0,
    this.createdAt,
    this.startDate,
    this.endDate,
    this.totalAmount,
    this.expenseAmount,
    this.margin,
  });

  String get unit => quantityUnit;

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? json['businessId'] as String? ?? '',
      productId: json['product_id'] as String? ?? json['productId'] as String? ?? '',
      productName: json['product_name'] as String? ?? json['productName'] as String?,
      batchCode: json['batch_code'] as String? ?? json['batchCode'] as String? ?? '',
      sourceMarketId: json['source_market_id'] as String? ?? json['sourceMarketId'] as String?,
      destinationMarketId: json['destination_market_id'] as String? ?? json['destinationMarketId'] as String?,
      purchaseDate: json['purchase_date'] as String? ?? json['purchaseDate'] as String? ?? '',
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? (json['totalQuantity'] as num?)?.toDouble() ?? 0,
      quantityUnit: json['quantity_unit'] as String? ?? json['quantityUnit'] as String? ?? 'kg',
      purchasePricePerUnit: (json['purchase_price_per_unit'] as num?)?.toDouble() ?? (json['purchasePricePerUnit'] as num?)?.toDouble() ?? 0,
      totalPurchaseCost: (json['total_purchase_cost'] as num?)?.toDouble() ?? (json['totalPurchaseCost'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'purchased',
      transportPaidBy: json['transport_paid_by'] as String? ?? json['transportPaidBy'] as String?,
      notes: json['notes'] as String?,
      supplierName: json['supplier_name'] as String? ?? json['supplierName'] as String?,
      purchasePaymentMode:
          json['purchase_payment_mode'] as String? ?? json['purchasePaymentMode'] as String?,
      purchaseAmountPaid: (json['purchase_amount_paid'] as num?)?.toDouble() ??
          (json['purchaseAmountPaid'] as num?)?.toDouble() ??
          0,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
      startDate: json['start_date'] as String? ?? json['startDate'] as String?,
      endDate: json['end_date'] as String? ?? json['endDate'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble(),
      expenseAmount: (json['expense_amount'] as num?)?.toDouble() ?? (json['expenseAmount'] as num?)?.toDouble(),
      margin: (json['margin'] as num?)?.toDouble(),
    );
  }
}

class BatchCreateRequest {
  final String businessId;
  final String productId;
  final String? sourceMarketId;
  final String? destinationMarketId;
  final String purchaseDate;
  final double totalQuantity;
  final String quantityUnit;
  final double purchasePricePerUnit;
  final String? transportPaidBy;
  final String? notes;
  final String? batchCode;
  final String? supplierName;
  final String? purchasePaymentMode;
  final double purchaseAmountPaid;
  final List<BatchPartnerCreate>? partners;
  final List<PackingRecordCreate>? packingRecords;
  final List<ExpenseCreate>? expenses;
  final List<VehicleLoadCreate>? vehicleLoads;

  BatchCreateRequest({
    required this.businessId,
    required this.productId,
    this.sourceMarketId,
    this.destinationMarketId,
    required this.purchaseDate,
    required this.totalQuantity,
    required this.quantityUnit,
    required this.purchasePricePerUnit,
    this.transportPaidBy,
    this.notes,
    this.batchCode,
    this.supplierName,
    this.purchasePaymentMode,
    this.purchaseAmountPaid = 0,
    this.partners,
    this.packingRecords,
    this.expenses,
    this.vehicleLoads,
  });

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'product_id': productId,
    'source_market_id': sourceMarketId,
    'destination_market_id': destinationMarketId,
    'purchase_date': purchaseDate,
    'total_quantity': totalQuantity,
    'quantity_unit': quantityUnit,
    'purchase_price_per_unit': purchasePricePerUnit,
    'transport_paid_by': transportPaidBy,
    'notes': notes,
    if (batchCode != null && batchCode!.isNotEmpty) 'batch_code': batchCode,
    if (supplierName != null && supplierName!.isNotEmpty) 'supplier_name': supplierName,
    if (purchasePaymentMode != null && purchasePaymentMode!.isNotEmpty)
      'purchase_payment_mode': purchasePaymentMode,
    'purchase_amount_paid': purchaseAmountPaid,
    'partners': partners?.map((e) => e.toJson()).toList(),
    'packing_records': packingRecords?.map((e) => e.toJson()).toList(),
    'expenses': expenses?.map((e) => e.toJson()).toList(),
    'vehicle_loads': vehicleLoads?.map((e) => e.toJson()).toList(),
  };
}

class BatchPartnerCreate {
  final String partnerId;
  final String role;
  final double? dailyChargeRate;
  final int? daysInvolved;

  BatchPartnerCreate({
    required this.partnerId,
    required this.role,
    this.dailyChargeRate,
    this.daysInvolved,
  });

  Map<String, dynamic> toJson() => {
    'partner_id': partnerId,
    'role': role,
    'daily_charge_rate': dailyChargeRate,
    'days_involved': daysInvolved,
  };
}

class PackingRecordCreate {
  final String unitType;
  final String? unitLabel;
  final int unitCount;
  final double costPerUnit;

  PackingRecordCreate({
    required this.unitType,
    this.unitLabel,
    required this.unitCount,
    required this.costPerUnit,
  });

  Map<String, dynamic> toJson() => {
    'unit_type': unitType,
    'unit_label': unitLabel,
    'unit_count': unitCount,
    'cost_per_unit': costPerUnit,
  };
}

class ExpenseCreate {
  final String? partnerId;
  final String expenseSide;
  final String expenseType;
  final double amount;
  final String? description;
  final String? paidBy;
  final String? paymentMode;
  final String? paymentReference;
  final String? expenseDate;

  ExpenseCreate({
    this.partnerId,
    required this.expenseSide,
    required this.expenseType,
    required this.amount,
    this.description,
    this.paidBy,
    this.paymentMode,
    this.paymentReference,
    this.expenseDate,
  });

  Map<String, dynamic> toJson() => {
    'partner_id': partnerId,
    'expense_side': expenseSide,
    'expense_type': expenseType,
    'amount': amount,
    'description': description,
    'paid_by': paidBy,
    'payment_mode': paymentMode,
    'bank_reference': paymentReference,
    'expense_date': expenseDate,
  };
}

class VehicleLoadCreate {
  final String vehicleId;
  final int? packingRecordIndex;
  final String? packingRecordId;
  final double unitCount;
  final String costType;
  final double transportCost;
  final String? loadDate;
  final String? notes;

  VehicleLoadCreate({
    required this.vehicleId,
    this.packingRecordIndex,
    this.packingRecordId,
    this.unitCount = 0,
    this.costType = 'per_vehicle',
    this.transportCost = 0,
    this.loadDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    'packing_record_index': packingRecordIndex,
    'packing_record_id': packingRecordId,
    'unit_count': unitCount,
    'cost_type': costType,
    'transport_cost': transportCost,
    'load_date': loadDate,
    'notes': notes,
  };
}
