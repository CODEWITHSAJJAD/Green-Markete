import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/sale_model.dart';

final saleRemoteDsProvider = Provider<SaleRemoteDs>((ref) {
  return SaleRemoteDs(ref.watch(dioProvider));
});

class SaleRemoteDs {
  final Dio _dio;
  SaleRemoteDs(this._dio);

  Future<SaleModel> create(SaleCreateRequest request) async {
    final response = await _dio.post('/sales', data: request.toJson());
    final data = response.data as Map<String, dynamic>;
    return SaleModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<SaleModel>> listByBatch(String batchId, {String? cursor, int limit = 50}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await _dio.get('/sales/batch/$batchId', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final list = data['data']?['items'] as List<dynamic>? ?? [];
    return list.map((e) => SaleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SaleModel>> listByCustomer(String customerId) async {
    final response = await _dio.get('/sales/customer/$customerId');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => SaleModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
