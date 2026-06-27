import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/batch_repository.dart';
import '../../data/models/batch_model.dart';

final dashboardSummaryProvider = FutureProvider.family<DashboardSummaryModel, String>((ref, businessId) async {
  final repo = ref.watch(reportRepositoryProvider);
  // The dashboard/summary endpoint returns DashboardSummaryModel
  // For now we use the report repository
  final creditReport = await repo.getCustomerCredit(businessId);
  final totalCredit = creditReport.fold<double>(0, (sum, c) => sum + c.outstandingBalance);

  final batchRepo = ref.watch(batchRepositoryProvider);
  final batchesResult = await batchRepo.list(businessId: businessId);
  final data = batchesResult['data'] as Map<String, dynamic>?;
  final items = data?['items'] as List<dynamic>? ?? [];
  final activeBatches = items.where((e) {
    final status = (e as Map<String, dynamic>)['status'] as String?;
    return status != 'closed';
  }).length;

  return DashboardSummaryModel(
    todaySales: 0,
    activeBatches: activeBatches,
    outstandingCredit: totalCredit,
  );
});

final activeBatchesProvider = FutureProvider.family<List<BatchModel>, String>((ref, businessId) async {
  final repo = ref.watch(batchRepositoryProvider);
  final result = await repo.list(businessId: businessId, status: 'selling');
  final data = result['data'] as Map<String, dynamic>?;
  final items = data?['items'] as List<dynamic>? ?? [];
  return items.map((e) => BatchModel.fromJson(e as Map<String, dynamic>)).toList();
});
