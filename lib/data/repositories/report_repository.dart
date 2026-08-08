import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/report_model.dart';

class ReportRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<PLSummaryModel> getPLSummary(
    String businessId, {
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _client.rpc(
      'get_business_pl_summary',
      params: {
        'p_business_id': businessId,
        if (dateFrom != null && dateFrom.isNotEmpty) 'p_from_date': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'p_to_date': dateTo,
      },
    );
    final data = response is Map<String, dynamic>
        ? response['data']
        : response;
    if (data is Map<String, dynamic>) {
      return PLSummaryModel.fromJson({...data, 'business_id': businessId});
    }
    return PLSummaryModel(businessId: businessId);
  }

  Future<List<CreditReportModel>> getCustomerCredit(
    String businessId, {
    double threshold = 0,
  }) async {
    final rows = await _client
        .from('customers')
        .select('id, full_name, phone, city, outstanding_balance')
        .eq('business_id', businessId)
        .gt('outstanding_balance', threshold)
        .order('outstanding_balance', ascending: false);
    return rows.map(CreditReportModel.fromJson).toList();
  }

  Future<List<CreditReportModel>> getOverdueCustomers(
    String businessId, {
    double threshold = 50000,
  }) async {
    final rows = await _client
        .from('customers')
        .select('id, full_name, phone, city, outstanding_balance')
        .eq('business_id', businessId)
        .gt('outstanding_balance', threshold)
        .order('outstanding_balance', ascending: false);
    return rows.map(CreditReportModel.fromJson).toList();
  }

  Future<PartnerPLModel> getPartnerPL(String partnerId, String batchId) async {
    final response = await _client.rpc(
      'get_partner_pl',
      params: {'p_partner_id': partnerId, 'p_batch_id': batchId},
    );
    final data = response is Map<String, dynamic> ? response['data'] : response;
    if (data is Map<String, dynamic>) {
      return PartnerPLModel.fromJson({
        ...data,
        'partner_id': partnerId,
        'batch_id': batchId,
      });
    }
    return PartnerPLModel(partnerId: partnerId, batchId: batchId);
  }

  Future<List<MarketPerformanceModel>> getCityMarketPerformance(
    String businessId,
  ) async {
    final rows = await _client
        .from('v_city_market_performance')
        .select()
        .eq('business_id', businessId)
        .order('profit_loss', ascending: false);
    return rows.map(MarketPerformanceModel.fromJson).toList();
  }
}
