class BatchPartnerModel {
  final String id;
  final String batchId;
  final String partnerId;
  final String role;
  final double dailyChargeRate;
  final int daysInvolved;

  BatchPartnerModel({
    required this.id,
    required this.batchId,
    required this.partnerId,
    required this.role,
    this.dailyChargeRate = 0,
    this.daysInvolved = 1,
  });

  factory BatchPartnerModel.fromJson(Map<String, dynamic> json) {
    return BatchPartnerModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      partnerId: json['partner_id'] as String,
      role: json['role'] as String,
      dailyChargeRate: (json['daily_charge_rate'] as num?)?.toDouble() ?? 0,
      daysInvolved: json['days_involved'] as int? ?? 1,
    );
  }
}
