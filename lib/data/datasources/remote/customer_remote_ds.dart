import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';

final customerRemoteDsProvider = Provider<CustomerRemoteDs>((ref) {
  return CustomerRemoteDs(ref.watch(dioProvider));
});

class CustomerRemoteDs {
  final Dio _dio;
  CustomerRemoteDs(this._dio);

  Future<List<CustomerModel>> list(String businessId, {String? search}) async {
    final params = <String, dynamic>{'business_id': businessId};
    if (search != null) params['search'] = search;
    final response = await _dio.get('/customers', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> create(Map<String, dynamic> customerData) async {
    final response = await _dio.post('/customers', data: customerData);
    final data = response.data as Map<String, dynamic>;
    return CustomerModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<CustomerLedgerEntry>> getLedger(String customerId) async {
    final response = await _dio.get('/customers/$customerId/ledger');
    final data = response.data as Map<String, dynamic>;
    final entries = data['data']?['entries'] as List<dynamic>? ?? [];
    return entries.map((e) => CustomerLedgerEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentModel> recordPayment(String customerId, PaymentCreateRequest payment) async {
    final response = await _dio.post('/customers/$customerId/payment', data: payment.toJson());
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
