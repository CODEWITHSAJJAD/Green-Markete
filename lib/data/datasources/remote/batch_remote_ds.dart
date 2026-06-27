import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/batch_model.dart';
import '../../models/batch_partner_model.dart';
import '../../models/packing_record_model.dart';
import '../../models/expense_model.dart';
import '../../models/sale_model.dart';
import '../../models/report_model.dart';

final batchRemoteDsProvider = Provider<BatchRemoteDs>((ref) {
  return BatchRemoteDs(ref.watch(dioProvider));
});

class BatchRemoteDs {
  final Dio _dio;
  BatchRemoteDs(this._dio);

  Future<Map<String, dynamic>> list({
    required String businessId,
    String? status,
    String? productId,
    String? cursor,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{
      'business_id': businessId,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (productId != null) params['product_id'] = productId;
    if (cursor != null) params['cursor'] = cursor;
    final response = await _dio.get('/batches', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<BatchModel> create(BatchCreateRequest request) async {
    final response = await _dio.post('/batches', data: request.toJson());
    final data = response.data as Map<String, dynamic>;
    return BatchModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<BatchModel> get(String id) async {
    final response = await _dio.get('/batches/$id');
    final data = response.data as Map<String, dynamic>;
    return BatchModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, String status) async {
    await _dio.put('/batches/$id/status', data: {'status': status});
  }

  Future<void> addPacking(String id, PackingRecordCreate packing) async {
    await _dio.post('/batches/$id/packing', data: packing.toJson());
  }

  Future<void> addPartner(String id, BatchPartnerCreate partner) async {
    await _dio.post('/batches/$id/partners', data: partner.toJson());
  }

  Future<BatchPLSummaryModel> getSummary(String id) async {
    final response = await _dio.get('/batches/$id/summary');
    final data = response.data as Map<String, dynamic>;
    return BatchPLSummaryModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
