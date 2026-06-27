import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/product_remote_ds.dart';
import '../models/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(productRemoteDsProvider));
});

class ProductRepository {
  final ProductRemoteDs _remoteDs;
  ProductRepository(this._remoteDs);

  Future<List<ProductModel>> list(String businessId, {String? category}) {
    return _remoteDs.list(businessId, category: category);
  }

  Future<ProductModel> create(Map<String, dynamic> data) {
    return _remoteDs.create(data);
  }

  Future<ProductModel> get(String id) {
    return _remoteDs.get(id);
  }
}
