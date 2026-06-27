class Sale {
  final String id;
  final double quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String paymentMode;
  final String? customerName;

  Sale({
    required this.id,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.paymentMode,
    this.customerName,
  });
}
