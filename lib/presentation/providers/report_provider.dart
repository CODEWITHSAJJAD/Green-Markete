import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';

final plSummaryProvider = FutureProvider.family<PLSummaryModel, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getPLSummary(
    params['business_id'] as String,
    dateFrom: params['date_from'] as String?,
    dateTo: params['date_to'] as String?,
  );
});

final creditReportProvider = FutureProvider.family<List<CreditReportModel>, String>((ref, businessId) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getCustomerCredit(businessId);
});

final overdueCustomersProvider = FutureProvider.family<List<CreditReportModel>, String>((ref, businessId) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getOverdueCustomers(businessId);
});
