import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/report_remote_ds.dart';
import '../models/report_model.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(reportRemoteDsProvider));
});

class ReportRepository {
  final ReportRemoteDs _remoteDs;
  ReportRepository(this._remoteDs);

  Future<PLSummaryModel> getPLSummary(String businessId, {String? dateFrom, String? dateTo}) {
    return _remoteDs.getPLSummary(businessId, dateFrom: dateFrom, dateTo: dateTo);
  }

  Future<String> exportBatchPDF(String batchId) {
    return _remoteDs.exportBatchPDF(batchId);
  }

  Future<List<CreditReportModel>> getCustomerCredit(String businessId, {double threshold = 0}) {
    return _remoteDs.getCustomerCredit(businessId, threshold: threshold);
  }

  Future<List<CreditReportModel>> getOverdueCustomers(String businessId, {double threshold = 50000}) {
    return _remoteDs.getOverdueCustomers(businessId, threshold: threshold);
  }

  Future<PartnerPLModel> getPartnerPL(String partnerId, String batchId) {
    return _remoteDs.getPartnerPL(partnerId, batchId);
  }

  Future<String> getPLExportCSV(String businessId, {String? dateFrom, String? dateTo}) {
    return _remoteDs.getPLExportCSV(businessId, dateFrom: dateFrom, dateTo: dateTo);
  }
}
