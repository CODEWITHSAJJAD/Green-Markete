import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/batch_model.dart';
import '../models/report_model.dart';

class BatchRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<BatchModel>> list({
    required String businessId,
    String? status,
    String? productId,
    String? cursor,
    int limit = 50,
  }) async {
    var query = _client
        .from('product_batches')
        .select('*, products(name)')
        .eq('business_id', businessId);
    if (status != null) query = query.eq('status', status);
    if (productId != null) query = query.eq('product_id', productId);
    if (cursor != null && cursor.isNotEmpty) {
      query = query.lt('created_at', cursor);
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return rows.map(_withProductName).map(BatchModel.fromJson).toList();
  }

  Future<BatchModel> create(BatchCreateRequest request) async {
    final row = await _client
        .from('product_batches')
        .insert({
          'business_id': request.businessId,
          'product_id': request.productId,
          'source_market_id': request.sourceMarketId,
          'destination_market_id': request.destinationMarketId,
          'purchase_date': request.purchaseDate,
          'total_quantity': request.totalQuantity,
          'quantity_unit': request.quantityUnit,
          'purchase_price_per_unit': request.purchasePricePerUnit,
          'total_purchase_cost': request.purchasePricePerUnit * request.totalQuantity,
          'transport_paid_by': request.transportPaidBy,
          'notes': request.notes,
        })
        .select()
        .single();

    final batchId = row['id'] as String;

    final partners = request.partners ?? const [];
    for (final p in partners) {
      await _client.from('batch_partners').insert({
        'batch_id': batchId,
        'partner_id': p.partnerId,
        'role': p.role,
        'daily_charge_rate': p.dailyChargeRate ?? 0,
        'days_involved': p.daysInvolved ?? 1,
      });
    }

    final packing = request.packingRecords ?? const [];
    for (final p in packing) {
      await _client.from('packing_records').insert({
        'batch_id': batchId,
        'unit_type_label': p.unitType,
        'unit_count': p.unitCount,
        'cost_per_unit': p.costPerUnit,
        'total_packing_cost': p.costPerUnit * p.unitCount,
      });
    }

    final expenses = request.expenses ?? const [];
    for (final e in expenses) {
      await _client.from('expenses').insert({
        'batch_id': batchId,
        'partner_id': e.partnerId,
        'expense_side': e.expenseSide,
        'expense_type': e.expenseType,
        'amount': e.amount,
        'description': e.description,
        'paid_by': e.paidBy,
        'payment_mode': e.paymentMode,
        'bank_reference': e.paymentReference,
        'expense_date': e.expenseDate ?? request.purchaseDate,
        'created_by': _client.auth.currentUser?.id,
      });
    }

    return BatchModel.fromJson(row);
  }

  Future<BatchModel> get(String id) async {
    final row = await _client
        .from('product_batches')
        .select('*, products(name)')
        .eq('id', id)
        .single();
    return BatchModel.fromJson(_withProductName(row));
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from('product_batches').update({'status': status}).eq('id', id);
  }

  Future<void> update(
    String id, {
    String? transportPaidBy,
    String? notes,
  }) async {
    await _client.from('product_batches').update({
      'transport_paid_by': ?transportPaidBy,
      'notes': ?notes,
    }).eq('id', id);
  }

  Future<void> addPacking(String id, PackingRecordCreate packing) async {
    await _client.from('packing_records').insert({
      'batch_id': id,
      'unit_type_label': packing.unitType,
      'unit_count': packing.unitCount,
      'cost_per_unit': packing.costPerUnit,
      'total_packing_cost': packing.costPerUnit * packing.unitCount,
    });
  }

  Future<void> addPartner(String id, BatchPartnerCreate partner) async {
    await _client.from('batch_partners').insert({
      'batch_id': id,
      'partner_id': partner.partnerId,
      'role': partner.role,
      'daily_charge_rate': partner.dailyChargeRate ?? 0,
      'days_involved': partner.daysInvolved ?? 1,
    });
  }

  Future<BatchPLDetailModel> getSummary(String id) async {
    final response = await _client
        .rpc('get_batch_pl', params: {'p_batch_id': id});
    final data = (response as Map<String, dynamic>)['data'];
    if (data is Map<String, dynamic>) {
      return BatchPLDetailModel.fromJson({...data, 'batch_id': id});
    }
    return BatchPLDetailModel(batchId: id);
  }

  Map<String, dynamic> _withProductName(Map<String, dynamic> row) {
    final product = row.remove('products');
    if (product is Map<String, dynamic> && product['name'] != null) {
      row['product_name'] = product['name'];
    }
    return row;
  }
}
