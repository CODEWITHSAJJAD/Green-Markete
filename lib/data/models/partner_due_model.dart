/// One batch's purchaser-side bill owed to a seller partner and how much of it
/// has already been settled for that batch.
class BatchDueModel {
  final String partnerId;
  final String batchId;
  final String batchCode;
  final String? productName;
  final double bill;
  final double paid;
  final double remaining;

  const BatchDueModel({
    required this.partnerId,
    required this.batchId,
    required this.batchCode,
    this.productName,
    this.bill = 0,
    this.paid = 0,
    this.remaining = 0,
  });

  bool get isFullySettled => remaining <= 0.01;
}

/// Aggregated dues owed to one partner across all their batches.
class PartnerDueModel {
  final String partnerId;
  final List<BatchDueModel> batches;

  const PartnerDueModel({required this.partnerId, required this.batches});

  double get totalBill => batches.fold<double>(0, (s, b) => s + b.bill);
  double get totalPaid => batches.fold<double>(0, (s, b) => s + b.paid);
  double get totalRemaining =>
      batches.fold<double>(0, (s, b) => s + b.remaining);
}
