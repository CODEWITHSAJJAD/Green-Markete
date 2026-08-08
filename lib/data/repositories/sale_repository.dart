import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/sale_model.dart';

class SaleRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<SaleModel> create(SaleCreateRequest request) async {
    final row = await _client
        .from('sales')
        .insert({
          'batch_id': request.batchId,
          'seller_id': request.sellerId ?? _client.auth.currentUser?.id,
          'customer_id': request.customerId,
          'sale_date': request.saleDate,
          'quantity_sold': request.quantitySold,
          'price_per_unit': request.pricePerUnit,
          'total_amount': request.quantitySold * request.pricePerUnit,
          'payment_mode': request.paymentMode,
          'cash_received': request.cashReceived,
          'credit_amount': request.creditAmount,
          'bank_reference': request.bankReference,
          'notes': request.notes,
        })
        .select()
        .single();
    return SaleModel.fromJson(row);
  }

  Future<List<SaleModel>> listByBatch(
    String batchId, {
    String? cursor,
    int limit = 50,
  }) async {
    var query = _client
        .from('sales')
        .select()
        .eq('batch_id', batchId);
    if (cursor != null && cursor.isNotEmpty) query = query.lt('sale_date', cursor);
    final rows = await query.order('sale_date', ascending: false).limit(limit);
    return rows.map(SaleModel.fromJson).toList();
  }

  Future<List<SaleModel>> listByCustomer(String customerId) async {
    final rows = await _client
        .from('sales')
        .select()
        .eq('customer_id', customerId)
        .order('sale_date', ascending: false);
    return rows.map(SaleModel.fromJson).toList();
  }
}
