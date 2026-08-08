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
      id: json['id'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? json['batchId'] as String? ?? '',
      partnerId: json['partner_id'] as String? ?? json['partnerId'] as String? ?? '',
      role: json['role'] as String? ?? 'purchaser',
      dailyChargeRate: (json['daily_charge_rate'] as num?)?.toDouble() ?? (json['dailyChargeRate'] as num?)?.toDouble() ?? 0,
      daysInvolved: (json['days_involved'] as int?) ?? (json['daysInvolved'] as int?) ?? 1,
    );
  }
}
