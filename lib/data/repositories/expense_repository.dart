import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/batch_model.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<ExpenseModel>> list(String batchId) async {
    final rows = await _client
        .from('expenses')
        .select()
        .eq('batch_id', batchId)
        .order('expense_date', ascending: false);
    return rows.map(ExpenseModel.fromJson).toList();
  }

  Future<ExpenseModel> create(String batchId, ExpenseCreate expense) async {
    final row = await _client
        .from('expenses')
        .insert({
          'batch_id': batchId,
          'partner_id': expense.partnerId,
          'expense_side': expense.expenseSide,
          'expense_type': expense.expenseType,
          'amount': expense.amount,
          'description': expense.description,
          'paid_by': expense.paidBy,
          'payment_mode': expense.paymentMode,
          'bank_reference': expense.paymentReference,
          'expense_date': expense.expenseDate,
          'created_by': _client.auth.currentUser?.id,
        })
        .select()
        .single();
    return ExpenseModel.fromJson(row);
  }

  Future<void> update(String id, ExpenseUpdateModel expense) async {
    await _client.from('expenses').update(expense.toJson()).eq('id', id);
  }

  Future<void> voidExpense(
    String id, {
    required String reason,
  }) async {
    await _client.from('expenses').update({
      'is_voided': true,
      'voided_by': _client.auth.currentUser?.id,
      'voided_reason': reason,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }
}
