class Expense {
  final String id;
  final double amount;
  final String expenseType;
  final String expenseSide;
  final String? description;
  final String? partnerName;

  Expense({
    required this.id,
    required this.amount,
    required this.expenseType,
    required this.expenseSide,
    this.description,
    this.partnerName,
  });
}
