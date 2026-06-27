import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

final customerListProvider = FutureProvider.family<List<CustomerModel>, String>((ref, businessId) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.list(businessId);
});

final customerSearchProvider = FutureProvider.family<List<CustomerModel>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.list(params['business_id'] as String, search: params['search'] as String?);
});

final customerLedgerProvider = FutureProvider.family<List<CustomerLedgerEntry>, String>((ref, customerId) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getLedger(customerId);
});
