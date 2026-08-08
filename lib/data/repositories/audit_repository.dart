import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/audit_log_model.dart';

class AuditRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<AuditLogModel>> list({
    String? performedBy,
    String? tableName,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    var q = _client.from('audit_logs').select();
    if (performedBy != null && performedBy.isNotEmpty) {
      q = q.eq('performed_by', performedBy);
    }
    if (tableName != null && tableName.isNotEmpty) {
      q = q.eq('table_name', tableName);
    }
    if (from != null) {
      q = q.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      q = q.lte('created_at', to.toIso8601String());
    }
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return rows.map(AuditLogModel.fromJson).toList();
  }
}