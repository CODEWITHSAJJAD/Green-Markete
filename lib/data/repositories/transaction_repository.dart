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
    final List<dynamic> transactions = await _client
        .from('partner_transactions')
        .select()
        .or('from_partner_id.eq.$partnerId,to_partner_id.eq.$partnerId')
        .order('transaction_date', ascending: false);

    double totalSent = 0;
    double totalReceived = 0;
    final entries = <Map<String, dynamic>>[];

    for (final raw in transactions) {
      if (raw is Map<String, dynamic>) {
        final amount = (raw['amount'] as num?)?.toDouble() ?? 0.0;
        final fromId = raw['from_partner_id'] as String?;
        final toId = raw['to_partner_id'] as String?;
        final isSent = fromId == partnerId;
        final isReceived = toId == partnerId;

        if (isSent) totalSent += amount;
        if (isReceived) totalReceived += amount;

        entries.add({
          'id': raw['id'],
          'description': raw['notes'] ??
              raw['reference'] ??
              raw['transaction_type'] ??
              'Payment',
          'date': raw['transaction_date'] ?? raw['created_at'] ?? '',
          'amount': amount,
          'type': isReceived ? 'received' : 'sent',
          'is_credit': isReceived,
          'notes': raw['notes'],
          'reference': raw['reference'],
        });
      }
    }

    final balanceMap = {
      'total_sent': totalSent,
      'total_received': totalReceived,
      'net_balance': totalReceived - totalSent,
    };

    return {
      'transactions': transactions,
      'total_in': totalReceived,
      'total_out': totalSent,
      'balance': balanceMap,
      'entries': entries,
      'data': {
        'balance': balanceMap,
        'entries': entries,
        'transactions': transactions,
      },
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
