class TransactionModel {
  final String id;
  final String businessId;
  final String fromPartnerId;
  final String toPartnerId;
  final double amount;
  final String? transactionType;
  final String? paymentMode;
  final String? reference;
  final String transactionDate;
  final String? notes;

  TransactionModel({
    required this.id,
    required this.businessId,
    required this.fromPartnerId,
    required this.toPartnerId,
    required this.amount,
    this.transactionType,
    this.paymentMode,
    this.reference,
    required this.transactionDate,
    this.notes,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? json['businessId'] as String? ?? '',
      fromPartnerId: json['from_partner_id'] as String? ?? json['fromPartnerId'] as String? ?? '',
      toPartnerId: json['to_partner_id'] as String? ?? json['toPartnerId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      transactionType: json['transaction_type'] as String? ?? json['transactionType'] as String?,
      paymentMode: json['payment_mode'] as String? ?? json['paymentMode'] as String?,
      reference: json['reference'] as String?,
      transactionDate: json['transaction_date'] as String? ?? json['transactionDate'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class TransactionCreateRequest {
  final String businessId;
  final String fromPartnerId;
  final String toPartnerId;
  final double amount;
  final String? transactionType;
  final String? paymentMode;
  final String? reference;
  final String transactionDate;
  final String? notes;

  TransactionCreateRequest({
    required this.businessId,
    required this.fromPartnerId,
    required this.toPartnerId,
    required this.amount,
    this.transactionType,
    this.paymentMode,
    this.reference,
    required this.transactionDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'from_partner_id': fromPartnerId,
    'to_partner_id': toPartnerId,
    'amount': amount,
    'transaction_type': transactionType,
    'payment_mode': paymentMode,
    'reference': reference,
    'transaction_date': transactionDate,
    'notes': notes,
  };
}
