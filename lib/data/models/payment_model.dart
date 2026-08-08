class PaymentModel {
  final String id;
  final String customerId;
  final String businessId;
  final double amount;
  final String paymentMode;
  final String? bankReference;
  final String paymentDate;
  final String? receivedBy;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.customerId,
    required this.businessId,
    required this.amount,
    required this.paymentMode,
    this.bankReference,
    required this.paymentDate,
    this.receivedBy,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
      businessId: json['business_id'] as String? ?? json['businessId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['payment_mode'] as String? ?? json['paymentMode'] as String? ?? 'cash',
      bankReference: json['bank_reference'] as String? ?? json['bankReference'] as String?,
      paymentDate: json['payment_date'] as String? ?? json['paymentDate'] as String? ?? '',
      receivedBy: json['received_by'] as String? ?? json['receivedBy'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class PaymentCreateRequest {
  final String customerId;
  final String businessId;
  final double amount;
  final String paymentMode;
  final String? bankReference;
  final String paymentDate;
  final String? receivedBy;
  final String? notes;

  PaymentCreateRequest({
    required this.customerId,
    required this.businessId,
    required this.amount,
    required this.paymentMode,
    this.bankReference,
    required this.paymentDate,
    this.receivedBy,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'business_id': businessId,
    'amount': amount,
    'payment_mode': paymentMode,
    'bank_reference': bankReference,
    'payment_date': paymentDate,
    'received_by': receivedBy,
    'notes': notes,
  };
}
