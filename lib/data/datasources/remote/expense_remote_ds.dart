import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/batch_model.dart';
import '../../models/expense_model.dart';

final expenseRemoteDsProvider = Provider<ExpenseRemoteDs>((ref) {
  return ExpenseRemoteDs(ref.watch(dioProvider));
});

class ExpenseRemoteDs {
  final Dio _dio;
  ExpenseRemoteDs(this._dio);

  Future<List<ExpenseModel>> list(String batchId) async {
    final response = await _dio.get('/batches/$batchId/expenses');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExpenseModel> create(String batchId, ExpenseCreate expense) async {
    final response = await _dio.post('/batches/$batchId/expenses', data: expense.toJson());
    final data = response.data as Map<String, dynamic>;
    return ExpenseModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> update(String id, ExpenseUpdateModel expense) async {
    await _dio.put('/expenses/$id', data: expense.toJson());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/expenses/$id');
  }
}
