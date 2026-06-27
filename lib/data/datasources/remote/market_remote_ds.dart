import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/market_model.dart';

final marketRemoteDsProvider = Provider<MarketRemoteDs>((ref) {
  return MarketRemoteDs(ref.watch(dioProvider));
});

class MarketRemoteDs {
  final Dio _dio;
  MarketRemoteDs(this._dio);

  Future<List<MarketModel>> list(String businessId, {String? city}) async {
    final params = <String, dynamic>{'business_id': businessId};
    if (city != null) params['city'] = city;
    final response = await _dio.get('/markets', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => MarketModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MarketModel> create(Map<String, dynamic> marketData) async {
    final response = await _dio.post('/markets', data: marketData);
    final data = response.data as Map<String, dynamic>;
    return MarketModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
