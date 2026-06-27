import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/partner_model.dart';

final partnerRemoteDsProvider = Provider<PartnerRemoteDs>((ref) {
  return PartnerRemoteDs(ref.watch(dioProvider));
});

class PartnerRemoteDs {
  final Dio _dio;
  PartnerRemoteDs(this._dio);

  Future<List<PartnerModel>> search(String query, String businessId) async {
    final response = await _dio.get('/partners/search', queryParameters: {
      'q': query,
      'business_id': businessId,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => PartnerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PartnerModel>> list(String businessId) async {
    final response = await _dio.get('/partners', queryParameters: {
      'business_id': businessId,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => PartnerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PartnerModel> create(Map<String, dynamic> partnerData) async {
    final response = await _dio.post('/partners/create', data: partnerData);
    final data = response.data as Map<String, dynamic>;
    return PartnerModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> invite(String partnerId) async {
    await _dio.post('/partners/$partnerId/invite');
  }

  Future<void> updateAccess(String partnerId, String accessLevel, String businessId) async {
    await _dio.put('/partners/$partnerId/access', queryParameters: {
      'business_id': businessId,
    }, data: {
      'access_level': accessLevel,
    });
  }
}
