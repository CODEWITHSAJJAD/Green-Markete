import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/sale_remote_ds.dart';
import '../models/sale_model.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository(ref.watch(saleRemoteDsProvider));
});

class SaleRepository {
  final SaleRemoteDs _remoteDs;
  SaleRepository(this._remoteDs);

  Future<SaleModel> create(SaleCreateRequest request) {
    return _remoteDs.create(request);
  }

  Future<List<SaleModel>> listByBatch(String batchId, {String? cursor, int limit = 50}) {
    return _remoteDs.listByBatch(batchId, cursor: cursor, limit: limit);
  }

  Future<List<SaleModel>> listByCustomer(String customerId) {
    return _remoteDs.listByCustomer(customerId);
  }
}
