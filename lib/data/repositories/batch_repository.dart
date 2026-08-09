import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/batch_model.dart';
import '../models/batch_vehicle_model.dart';
import '../models/packing_record_model.dart';
import '../models/packing_return_model.dart';
import '../models/report_model.dart';

class BatchRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<Map<String, dynamic>> _insertBatchWithRetry(
    BatchCreateRequest request, {
    int maxAttempts = 4,
  }) async {
    final basePayload = {
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
      'supplier_name': request.supplierName,
      'purchase_payment_mode': request.purchasePaymentMode,
      'purchase_amount_paid': request.purchaseAmountPaid,
    };
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final payload = {
        ...basePayload,
        if (request.batchCode != null && request.batchCode!.isNotEmpty)
          'batch_code': request.batchCode,
      };
      try {
        return await _client
            .from('product_batches')
            .insert(payload)
            .select()
            .single();
      } on PostgrestException catch (e) {
        lastError = e;
        // Columns added in later builds (supplier/purchase payment) may be
        // missing on the live DB — retry without them so creation still works.
        if (e.code == '42703' &&
            (basePayload['supplier_name'] != null ||
                basePayload['purchase_payment_mode'] != null ||
                basePayload['purchase_amount_paid'] != 0)) {
          final retryPayload = Map<String, dynamic>.from(payload)
            ..remove('supplier_name')
            ..remove('purchase_payment_mode')
            ..remove('purchase_amount_paid');
          return await _client
              .from('product_batches')
              .insert(retryPayload)
              .select()
              .single();
        }
        final isDuplicateBatchCode = e.toString().contains('product_batches_batch_code') ||
            e.code == '23505';
        if (!isDuplicateBatchCode || attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 80 * attempt));
      } catch (e) {
        lastError = e;
        final isDuplicateBatchCode = e.toString().contains('product_batches_batch_code') ||
            (e is PostgrestException && e.code == '23505');
        if (!isDuplicateBatchCode || attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 80 * attempt));
      }
    }
    throw lastError ?? Exception('Failed to create batch');
  }

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
    final row = await _insertBatchWithRetry(request);

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
    final packingIds = <String>[];
    for (final p in packing) {
      final row = await _client
          .from('packing_records')
          .insert({
            'batch_id': batchId,
            'unit_type_label': p.unitType,
            'unit_count': p.unitCount,
            'cost_per_unit': p.costPerUnit,
            'total_packing_cost': p.costPerUnit * p.unitCount,
          })
          .select('id')
          .single();
      packingIds.add(row['id'] as String);
    }

    final loads = request.vehicleLoads ?? const [];
    for (final load in loads) {
      await _client.from('batch_vehicles').insert({
        'batch_id': batchId,
        'vehicle_id': load.vehicleId,
        if (load.packingRecordIndex != null &&
            load.packingRecordIndex! >= 0 &&
            load.packingRecordIndex! < packingIds.length)
          'packing_record_id': packingIds[load.packingRecordIndex!],
        'unit_count': load.unitCount,
        'cost_type': load.costType,
        'transport_cost': load.transportCost,
        if (load.loadDate != null && load.loadDate!.isNotEmpty) 'load_date': load.loadDate,
        if (load.notes != null && load.notes!.isNotEmpty) 'notes': load.notes,
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

  Future<List<PackingRecordModel>> listPacking(String batchId) async {
    final rows = await _client
        .from('packing_records')
        .select()
        .eq('batch_id', batchId)
        .order('created_at', ascending: true);
    return rows.map(PackingRecordModel.fromJson).toList();
  }

  Future<List<BatchVehicleModel>> listVehicles(String batchId) async {
    final rows = await _client
        .from('batch_vehicles')
        .select('*, vehicles(plate_number, driver_name)')
        .eq('batch_id', batchId)
        .order('load_date', ascending: true);
    return rows.map(BatchVehicleModel.fromJson).toList();
  }

  Future<void> addVehicleLoad(String batchId, VehicleLoadCreate load) async {
    await _client.from('batch_vehicles').insert({
      'batch_id': batchId,
      'vehicle_id': load.vehicleId,
      if (load.packingRecordId != null) 'packing_record_id': load.packingRecordId,
      'unit_count': load.unitCount,
      'cost_type': load.costType,
      'transport_cost': load.transportCost,
      if (load.loadDate != null && load.loadDate!.isNotEmpty) 'load_date': load.loadDate,
      if (load.notes != null && load.notes!.isNotEmpty) 'notes': load.notes,
    });
  }

  Future<void> deleteVehicleLoad(String loadId) async {
    await _client.from('batch_vehicles').delete().eq('id', loadId);
  }

  Future<List<PackingReturnModel>> listReturns(String batchId) async {
    final rows = await _client
        .from('packing_returns')
        .select('*, packing_records(unit_type_label, cost_per_unit)')
        .eq('batch_id', batchId)
        .order('return_date', ascending: false);
    return rows.map(PackingReturnModel.fromJson).toList();
  }

  Future<void> addReturn(String batchId, PackingReturnCreate item) async {
    await _client.from('packing_returns').insert({
      'batch_id': batchId,
      'packing_record_id': item.packingRecordId,
      'quantity': item.quantity,
      if (item.count != null && item.count! > 0) 'count': item.count,
      if (item.returnDate != null && item.returnDate!.isNotEmpty)
        'return_date': item.returnDate,
      if (item.notes != null && item.notes!.isNotEmpty) 'notes': item.notes,
    });
  }

  Future<void> deleteReturn(String returnId) async {
    await _client.from('packing_returns').delete().eq('id', returnId);
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
