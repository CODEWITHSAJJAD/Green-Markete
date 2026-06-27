class SaleModel {
  final String id;
  final String batchId;
  final String? sellerId;
  final String? customerId;
  final String saleDate;
  final double quantitySold;
  final double pricePerUnit;
  final double totalAmount;
  final String paymentMode;
  final double cashReceived;
  final double creditAmount;
  final String? bankReference;
  final String? notes;

  SaleModel({
    required this.id,
    required this.batchId,
    this.sellerId,
    this.customerId,
    required this.saleDate,
    required this.quantitySold,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.paymentMode,
    this.cashReceived = 0,
    this.creditAmount = 0,
    this.bankReference,
    this.notes,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      sellerId: json['seller_id'] as String?,
      customerId: json['customer_id'] as String?,
      saleDate: json['sale_date'] as String,
      quantitySold: (json['quantity_sold'] as num).toDouble(),
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ??
          (json['quantity_sold'] as num).toDouble() * (json['price_per_unit'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      cashReceived: (json['cash_received'] as num?)?.toDouble() ?? 0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0,
      bankReference: json['bank_reference'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class SaleCreateRequest {
  final String batchId;
  final String? sellerId;
  final String? customerId;
  final String saleDate;
  final double quantitySold;
  final double pricePerUnit;
  final String paymentMode;
  final double cashReceived;
  final double creditAmount;
  final String? bankReference;
  final String? notes;

  SaleCreateRequest({
    required this.batchId,
    this.sellerId,
    this.customerId,
    required this.saleDate,
    required this.quantitySold,
    required this.pricePerUnit,
    required this.paymentMode,
    this.cashReceived = 0,
    this.creditAmount = 0,
    this.bankReference,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'seller_id': sellerId,
    'customer_id': customerId,
    'sale_date': saleDate,
    'quantity_sold': quantitySold,
    'price_per_unit': pricePerUnit,
    'payment_mode': paymentMode,
    'cash_received': cashReceived,
    'credit_amount': creditAmount,
    'bank_reference': bankReference,
    'notes': notes,
  };
}
