import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';

final salesByBatchProvider = FutureProvider.family<List<SaleModel>, String>((ref, batchId) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.listByBatch(batchId);
});

final salesByCustomerProvider = FutureProvider.family<List<SaleModel>, String>((ref, customerId) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.listByCustomer(customerId);
});
