class Batch {
  final String id;
  final String batchCode;
  final String status;
  final String productName;
  final double totalQuantity;
  final String quantityUnit;
  final String? sourceCity;
  final String? destinationCity;

  Batch({
    required this.id,
    required this.batchCode,
    required this.status,
    required this.productName,
    required this.totalQuantity,
    required this.quantityUnit,
    this.sourceCity,
    this.destinationCity,
  });
}
