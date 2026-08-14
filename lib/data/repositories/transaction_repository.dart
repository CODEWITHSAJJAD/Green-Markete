import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<TransactionModel> create(TransactionCreateRequest request) async {
    final row = await _client
        .from('partner_transactions')
        .insert({
          'business_id': request.businessId,
          'from_partner_id': request.fromPartnerId,
          'to_partner_id': request.toPartnerId,
          'amount': request.amount,
          'transaction_type': request.transactionType,
          'payment_mode': request.paymentMode,
          'reference': request.reference,
          'transaction_date': request.transactionDate,
          'notes': request.notes,
        })
        .select()
        .single();
    return TransactionModel.fromJson(row);
  }

  Future<Map<String, dynamic>> getPartnerLedger(String partnerId) async {
    final transactions = await _client
        .from('partner_transactions')
        .select()
        .or('from_partner_id.eq.$partnerId,to_partner_id.eq.$partnerId')
        .order('transaction_date', ascending: false);
    return {
      'transactions': transactions,
      'total_in': 0,
      'total_out': 0,
    };
  }

  /// Every partner transaction for the business, newest first. Used by the
  /// partner dues screen to match settled amounts to batches via the batch
  /// code stored in the notes or reference.
  Future<List<TransactionModel>> listByBusiness(String businessId) async {
    final rows = await _client
        .from('partner_transactions')
        .select()
        .eq('business_id', businessId)
        .order('transaction_date', ascending: false);
    return rows.map(TransactionModel.fromJson).toList();
  }
}
