import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/transaction_model.dart';

final transactionRemoteDsProvider = Provider<TransactionRemoteDs>((ref) {
  return TransactionRemoteDs(ref.watch(dioProvider));
});

class TransactionRemoteDs {
  final Dio _dio;
  TransactionRemoteDs(this._dio);

  Future<TransactionModel> create(TransactionCreateRequest request) async {
    final response = await _dio.post('/transactions', data: request.toJson());
    final data = response.data as Map<String, dynamic>;
    return TransactionModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPartnerLedger(String partnerId) async {
    final response = await _dio.get('/transactions/partner/$partnerId');
    return response.data as Map<String, dynamic>;
  }
}
