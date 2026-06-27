class Customer {
  final String id;
  final String fullName;
  final double outstandingBalance;

  Customer({
    required this.id,
    required this.fullName,
    this.outstandingBalance = 0,
  });
}
