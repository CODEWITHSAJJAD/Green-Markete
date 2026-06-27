import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/batch_remote_ds.dart';
import '../models/batch_model.dart';
import '../models/batch_partner_model.dart';
import '../models/packing_record_model.dart';
import '../models/report_model.dart';

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository(ref.watch(batchRemoteDsProvider));
});

class BatchRepository {
  final BatchRemoteDs _remoteDs;
  BatchRepository(this._remoteDs);

  Future<Map<String, dynamic>> list({
    required String businessId,
    String? status,
    String? productId,
    String? cursor,
    int limit = 50,
  }) {
    return _remoteDs.list(
      businessId: businessId,
      status: status,
      productId: productId,
      cursor: cursor,
      limit: limit,
    );
  }

  Future<BatchModel> create(BatchCreateRequest request) {
    return _remoteDs.create(request);
  }

  Future<BatchModel> get(String id) {
    return _remoteDs.get(id);
  }

  Future<void> updateStatus(String id, String status) {
    return _remoteDs.updateStatus(id, status);
  }

  Future<void> addPacking(String id, PackingRecordCreate packing) {
    return _remoteDs.addPacking(id, packing);
  }

  Future<void> addPartner(String id, BatchPartnerCreate partner) {
    return _remoteDs.addPartner(id, partner);
  }

  Future<BatchPLSummaryModel> getSummary(String id) {
    return _remoteDs.getSummary(id);
  }
}
