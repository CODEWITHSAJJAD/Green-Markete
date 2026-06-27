import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/product_model.dart';

final productRemoteDsProvider = Provider<ProductRemoteDs>((ref) {
  return ProductRemoteDs(ref.watch(dioProvider));
});

class ProductRemoteDs {
  final Dio _dio;
  ProductRemoteDs(this._dio);

  Future<List<ProductModel>> list(String businessId, {String? category}) async {
    final params = <String, dynamic>{'business_id': businessId};
    if (category != null) params['category'] = category;
    final response = await _dio.get('/products', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> create(Map<String, dynamic> productData) async {
    final response = await _dio.post('/products', data: productData);
    final data = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ProductModel> get(String id) async {
    final response = await _dio.get('/products/$id');
    final data = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
