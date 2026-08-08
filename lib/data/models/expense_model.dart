class ExpenseModel {
  final String id;
  final String batchId;
  final String? partnerId;
  final String expenseSide;
  final String expenseType;
  final double amount;
  final String? description;
  final String? paidBy;
  final String? paymentMode;
  final String? paymentReference;
  final String? expenseDate;
  final bool isVoided;
  final String? voidedBy;
  final String? voidedReason;
  final String? createdBy;

  ExpenseModel({
    required this.id,
    required this.batchId,
    this.partnerId,
    required this.expenseSide,
    required this.expenseType,
    required this.amount,
    this.description,
    this.paidBy,
    this.paymentMode,
    this.paymentReference,
    this.expenseDate,
    this.isVoided = false,
    this.voidedBy,
    this.voidedReason,
    this.createdBy,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      partnerId: json['partner_id'] as String?,
      expenseSide: json['expense_side'] as String,
      expenseType: json['expense_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      paidBy: json['paid_by'] as String?,
      paymentMode: json['payment_mode'] as String?,
      paymentReference:
          json['bank_reference'] as String? ?? json['payment_reference'] as String?,
      expenseDate: json['expense_date'] as String?,
      isVoided: json['is_voided'] as bool? ?? false,
      voidedBy: json['voided_by'] as String?,
      voidedReason: json['voided_reason'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }
}

class ExpenseUpdateModel {
  final double? amount;
  final String? description;
  final String? paymentMode;
  final String? paymentReference;
  final bool? isVoided;
  final String? voidedReason;

  ExpenseUpdateModel({
    this.amount,
    this.description,
    this.paymentMode,
    this.paymentReference,
    this.isVoided,
    this.voidedReason,
  });

  Map<String, dynamic> toJson() => {
    if (amount != null) 'amount': amount,
    if (description != null) 'description': description,
    if (paymentMode != null) 'payment_mode': paymentMode,
    if (paymentReference != null) 'bank_reference': paymentReference,
    if (isVoided != null) 'is_voided': isVoided,
    if (voidedReason != null) 'voided_reason': voidedReason,
  };
}
