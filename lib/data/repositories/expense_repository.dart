import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/expense_remote_ds.dart';
import '../models/expense_model.dart';
import '../models/batch_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(expenseRemoteDsProvider));
});

class ExpenseRepository {
  final ExpenseRemoteDs _remoteDs;
  ExpenseRepository(this._remoteDs);

  Future<List<ExpenseModel>> list(String batchId) {
    return _remoteDs.list(batchId);
  }

  Future<ExpenseModel> create(String batchId, ExpenseCreate expense) {
    return _remoteDs.create(batchId, expense);
  }

  Future<void> update(String id, ExpenseUpdateModel expense) {
    return _remoteDs.update(id, expense);
  }

  Future<void> delete(String id) {
    return _remoteDs.delete(id);
  }
}
