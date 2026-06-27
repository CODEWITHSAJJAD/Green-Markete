import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseListProvider = FutureProvider.family<List<ExpenseModel>, String>((ref, batchId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.list(batchId);
});
