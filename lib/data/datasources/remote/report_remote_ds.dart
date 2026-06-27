import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/report_model.dart';
import '../../models/customer_model.dart';

final reportRemoteDsProvider = Provider<ReportRemoteDs>((ref) {
  return ReportRemoteDs(ref.watch(dioProvider));
});

class ReportRemoteDs {
  final Dio _dio;
  ReportRemoteDs(this._dio);

  Future<PLSummaryModel> getPLSummary(String businessId, {String? dateFrom, String? dateTo}) async {
    final params = <String, dynamic>{'business_id': businessId};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    final response = await _dio.get('/reports/pl-summary', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    return PLSummaryModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<String> exportBatchPDF(String batchId) async {
    final response = await _dio.get('/reports/batch/$batchId/export');
    return response.data as String;
  }

  Future<List<CreditReportModel>> getCustomerCredit(String businessId, {double threshold = 0}) async {
    final response = await _dio.get('/reports/customer-credit', queryParameters: {
      'business_id': businessId,
      'threshold': threshold,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data']?['customers'] as List<dynamic>? ?? [];
    return list.map((e) => CreditReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CreditReportModel>> getOverdueCustomers(String businessId, {double threshold = 50000}) async {
    final response = await _dio.get('/reports/overdue-customers', queryParameters: {
      'business_id': businessId,
      'threshold': threshold,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => CreditReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PartnerPLModel> getPartnerPL(String partnerId, String batchId) async {
    final response = await _dio.get('/reports/partner-pl/$partnerId/batch/$batchId');
    final data = response.data as Map<String, dynamic>;
    return PartnerPLModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<String> getPLExportCSV(String businessId, {String? dateFrom, String? dateTo}) async {
    final params = <String, dynamic>{'business_id': businessId};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    final response = await _dio.get('/reports/pl-summary/export', queryParameters: params);
    return response.data as String;
  }
}
