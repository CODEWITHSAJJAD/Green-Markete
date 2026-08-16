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

  Future<List<SaleModel>> listByBusiness(
    String businessId, {
    int limit = 100,
  }) async {
    try {
      List<dynamic> batches;
      try {
        batches = await _client
            .from('product_batches')
            .select('id')
            .eq('business_id', businessId);
      } catch (_) {
        batches = await _client
            .from('batches')
            .select('id')
            .eq('business_id', businessId);
      }
      final batchIds = batches.map((b) => b['id'].toString()).toList();
      if (batchIds.isEmpty) return [];
      final rows = await _client
          .from('sales')
          .select()
          .filter('batch_id', 'in', batchIds)
          .order('sale_date', ascending: false)
          .limit(limit);
      return rows.map((r) => SaleModel.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Collects part or all of a sale's credit, moving the collected amount from
  /// `credit_amount` into `cash_received` so the sale total stays intact.
  /// Returns the updated sale, or `null` if the sale no longer exists.
  Future<SaleModel?> collectCredit(
    String saleId,
    double amount, {
    String paymentMode = 'cash',
    String? bankReference,
  }) async {
    final rows = await _client
        .from('sales')
        .select()
        .eq('id', saleId)
        .limit(1);
    if (rows.isEmpty) return null;
    final sale = SaleModel.fromJson(rows.first);
    final toCollect = amount.clamp(0, sale.creditAmount).toDouble();
    if (toCollect <= 0) return sale;
    final remaining = sale.creditAmount - toCollect;
    final row = await _client
        .from('sales')
        .update({
          'credit_amount': remaining,
          'cash_received': sale.cashReceived + toCollect,
          if (remaining <= 0.001) 'payment_mode': paymentMode,
          if (bankReference != null && bankReference.isNotEmpty)
            'bank_reference': bankReference,
        })
        .eq('id', saleId)
        .select()
        .single();
    return SaleModel.fromJson(row);
  }

  Future<SaleModel> update(String id, SaleUpdateRequest request) async {
    final row = await _client
        .from('sales')
        .update(request.toJson())
        .eq('id', id)
        .select()
        .single();
    return SaleModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('sales').delete().eq('id', id);
  }
}
