class SupplierPaymentModel {
  final String id;
  final String businessId;
  final String supplierName;
  final double amount;
  final String paymentMode;
  final String? bankReference;
  final String paymentDate;
  final String? receivedBy;
  final String? notes;

  SupplierPaymentModel({
    required this.id,
    required this.businessId,
    required this.supplierName,
    required this.amount,
    required this.paymentMode,
    this.bankReference,
    required this.paymentDate,
    this.receivedBy,
    this.notes,
  });

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json) {
    return SupplierPaymentModel(
      id: json['id'] as String? ?? '',
      businessId:
          json['business_id'] as String? ?? json['businessId'] as String? ?? '',
      supplierName:
          json['supplier_name'] as String? ??
          json['supplierName'] as String? ??
          '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMode:
          json['payment_mode'] as String? ??
          json['paymentMode'] as String? ??
          'cash',
      bankReference:
          json['bank_reference'] as String? ?? json['bankReference'] as String?,
      paymentDate:
          json['payment_date'] as String? ??
          json['paymentDate'] as String? ??
          '',
      receivedBy:
          json['received_by'] as String? ?? json['receivedBy'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class SupplierPaymentCreateRequest {
  final String businessId;
  final String supplierName;
  final double amount;
  final String paymentMode;
  final String? bankReference;
  final String paymentDate;
  final String? receivedBy;
  final String? notes;

  SupplierPaymentCreateRequest({
    required this.businessId,
    required this.supplierName,
    required this.amount,
    required this.paymentMode,
    this.bankReference,
    required this.paymentDate,
    this.receivedBy,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'supplier_name': supplierName,
    'amount': amount,
    'payment_mode': paymentMode,
    'bank_reference': bankReference,
    'payment_date': paymentDate,
    'received_by': receivedBy,
    'notes': notes,
  };
}

class SupplierOutstanding {
  final String supplierName;
  final double totalDue;
  final double totalPaidAtPurchase;
  final double totalPaidAfter;
  final double outstanding;

  SupplierOutstanding({
    required this.supplierName,
    required this.totalDue,
    required this.totalPaidAtPurchase,
    required this.totalPaidAfter,
    required this.outstanding,
  });

  double get totalPaid => totalPaidAtPurchase + totalPaidAfter;
}

class SupplierLedgerEntry {
  final String date;
  final String description;
  final double amount;
  final double runningBalance;
  final String type;
  final String? batchCode;
  final double paidAtPurchase;

  SupplierLedgerEntry({
    required this.date,
    required this.description,
    required this.amount,
    required this.runningBalance,
    required this.type,
    this.batchCode,
    this.paidAtPurchase = 0,
  });
}

/// Debt/paid/remaining for one supplier in one batch — used by the per-batch
/// view in supplier settlements. Aggregated from `batch_purchases` only
/// (later `supplier_payments` are not tied to a batch, so `paidAfter` is
/// tracked at supplier level, not per batch).
class SupplierBatchSummary {
  final String supplierName;
  final String batchCode;
  final String purchaseDate;
  final double debt;
  final double paidAtPurchase;

  SupplierBatchSummary({
    required this.supplierName,
    required this.batchCode,
    required this.purchaseDate,
    required this.debt,
    required this.paidAtPurchase,
  });

  double get remaining => (debt - paidAtPurchase).clamp(0, double.infinity);
}
