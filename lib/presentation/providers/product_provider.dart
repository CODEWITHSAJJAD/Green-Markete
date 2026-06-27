import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

final productListProvider = FutureProvider.family<List<ProductModel>, String>((ref, businessId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.list(businessId);
});

final productDetailProvider = FutureProvider.family<ProductModel, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.get(id);
});
