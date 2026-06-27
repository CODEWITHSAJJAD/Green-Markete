class PaymentModel {
  final String id;
  final String customerId;
  final String businessId;
  final double amount;
  final String paymentMode;
  final String? bankReference;
  final String? paymentDate;
  final String? receivedBy;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.customerId,
    required this.businessId,
    required this.amount,
    required this.paymentMode,
    this.bankReference,
    this.paymentDate,
    this.receivedBy,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      businessId: json['business_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String,
      bankReference: json['bank_reference'] as String?,
      paymentDate: json['payment_date'] as String?,
      receivedBy: json['received_by'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class PaymentCreateRequest {
  final String businessId;
  final double amount;
  final String paymentMode;
  final String? bankReference;
  final String paymentDate;
  final String? receivedBy;
  final String? notes;

  PaymentCreateRequest({
    required this.businessId,
    required this.amount,
    required this.paymentMode,
    this.bankReference,
    required this.paymentDate,
    this.receivedBy,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'amount': amount,
    'payment_mode': paymentMode,
    'bank_reference': bankReference,
    'payment_date': paymentDate,
    'received_by': receivedBy,
    'notes': notes,
  };
}
