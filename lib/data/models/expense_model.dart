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
      paymentReference: json['payment_reference'] as String?,
      expenseDate: json['expense_date'] as String?,
    );
  }
}

class ExpenseUpdateModel {
  final double? amount;
  final String? description;
  final String? paymentMode;
  final String? paymentReference;

  ExpenseUpdateModel({
    this.amount,
    this.description,
    this.paymentMode,
    this.paymentReference,
  });

  Map<String, dynamic> toJson() => {
    if (amount != null) 'amount': amount,
    if (description != null) 'description': description,
    if (paymentMode != null) 'payment_mode': paymentMode,
    if (paymentReference != null) 'payment_reference': paymentReference,
  };
}
