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
        'p_from_date':
            (dateFrom != null && dateFrom.isNotEmpty) ? dateFrom : '1900-01-01',
        'p_to_date':
            (dateTo != null && dateTo.isNotEmpty) ? dateTo : '2100-01-01',
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
  }) => _liveCreditReport(businessId, threshold: threshold);

  Future<List<CreditReportModel>> getOverdueCustomers(
    String businessId, {
    double threshold = 50000,
  }) => _liveCreditReport(businessId, threshold: threshold);

  /// Live outstanding balance per customer, summed from `sales.credit_amount`
  /// instead of the DB-maintained `customers.outstanding_balance` cache,
  /// which can drift out of sync after a partial payment.
  Future<List<CreditReportModel>> _liveCreditReport(
    String businessId, {
    required double threshold,
  }) async {
    final custRows = await _client
        .from('customers')
        .select('id, full_name, phone, city')
        .eq('business_id', businessId);
    final custList = List<Map<String, dynamic>>.from(custRows);
    final ids = custList.map((c) => c['id'] as String).toList();
    final balances = <String, double>{};
    if (ids.isNotEmpty) {
      final salesRows = await _client
          .from('sales')
          .select('customer_id, credit_amount')
          .inFilter('customer_id', ids);
      for (final r in salesRows) {
        final id = r['customer_id'] as String?;
        if (id == null) continue;
        final credit = (r['credit_amount'] as num?)?.toDouble() ?? 0.0;
        if (credit <= 0.001) continue;
        balances[id] = (balances[id] ?? 0) + credit;
      }
    }
    final result = custList
        .map(
          (c) => CreditReportModel.fromJson({
            ...c,
            'outstanding_balance': balances[c['id']] ?? 0.0,
          }),
        )
        .where((c) => c.outstandingBalance > threshold)
        .toList();
    result.sort(
      (a, b) => b.outstandingBalance.compareTo(a.outstandingBalance),
    );
    return result;
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
