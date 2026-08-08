class AuditLogModel {
  final String id;
  final String tableName;
  final String recordId;
  final String action;
  final String? performedBy;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? createdAt;

  AuditLogModel({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    this.performedBy,
    this.oldValues,
    this.newValues,
    this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      tableName: json['table_name'] as String? ?? '',
      recordId: json['record_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      performedBy: json['performed_by'] as String?,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );
  }
}