import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/batch_model.dart';
import '../models/batch_vehicle_model.dart';
import '../models/packing_record_model.dart';
import '../models/packing_return_model.dart';
import '../models/report_model.dart';
import '../models/supplier_payment_model.dart';

class _SupplierAgg {
  final String name;
  double totalDue = 0;
  double totalPaidAtPurchase = 0;
  double totalPaidAfter = 0;

  _SupplierAgg({
    required this.name,
    this.totalDue = 0,
    this.totalPaidAtPurchase = 0,
    this.totalPaidAfter = 0,
  });

  void merge(_SupplierAgg other) {
    totalDue += other.totalDue;
    totalPaidAtPurchase += other.totalPaidAtPurchase;
    totalPaidAfter += other.totalPaidAfter;
  }
}

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
      'total_purchase_cost':
          request.purchasePricePerUnit * request.totalQuantity,
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
        final isDuplicateBatchCode =
            e.toString().contains('product_batches_batch_code') ||
            e.code == '23505';
        if (!isDuplicateBatchCode || attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 80 * attempt));
      } catch (e) {
        lastError = e;
        final isDuplicateBatchCode =
            e.toString().contains('product_batches_batch_code') ||
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
    final mapped = rows.map(_withProductName).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final r in mapped) {
        final id = r['id']?.toString();
        if (id != null) {
          final localStatus = prefs.getString('batch_status_$id');
          if (localStatus != null && localStatus.isNotEmpty) {
            r['status'] = localStatus;
          }
        }
      }
    } catch (_) {}
    return mapped.map(BatchModel.fromJson).toList();
  }

  Future<BatchModel> create(BatchCreateRequest request) async {
    final row = await _insertBatchWithRetry(request);

    final batchId = row['id'] as String;

    final partners = request.partners ?? const [];
    for (final p in partners) {
      try {
        await _client.from('batch_partners').insert({
          'batch_id': batchId,
          'partner_id': p.partnerId,
          'role': p.role,
          'daily_charge_rate': p.dailyChargeRate ?? 0,
          'days_involved': p.daysInvolved ?? 1,
        });
      } on PostgrestException catch (e) {
        debugPrint(
          'batch_partners insert skipped for batch $batchId: ${e.code} ${e.message}',
        );
      }
    }

    final packing = request.packingRecords ?? const [];
    final packingIds = <String>[];
    for (final p in packing) {
      try {
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
      } on PostgrestException catch (e) {
        debugPrint(
          'packing_records insert skipped for batch $batchId: ${e.code} ${e.message}',
        );
      }
    }

    final loads = request.vehicleLoads ?? const [];
    for (final load in loads) {
      try {
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
          if (load.loadDate != null && load.loadDate!.isNotEmpty)
            'load_date': load.loadDate,
          if (load.notes != null && load.notes!.isNotEmpty) 'notes': load.notes,
        });
      } on PostgrestException catch (e) {
        debugPrint(
          'batch_vehicles insert skipped for batch $batchId: ${e.code} ${e.message}',
        );
      }
    }

    final expenses = request.expenses ?? const [];
    for (final e in expenses) {
      try {
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
      } on PostgrestException catch (e) {
        debugPrint(
          'expenses insert skipped for batch $batchId: ${e.code} ${e.message}',
        );
      }
    }

    final purchases = request.purchases ?? const [];
    for (final p in purchases) {
      try {
        await _client.from('batch_purchases').insert({
          'batch_id': batchId,
          'market_id': p.marketId,
          'supplier_name': p.supplierName,
          'unit_label': p.unitLabel,
          'unit_kg': p.unitKg,
          'quantity': p.quantity,
          'price_per_unit': p.pricePerUnit,
          'payment_mode': p.paymentMode,
          'amount_paid': p.amountPaid,
        });
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST205' || e.code == '42P01') {
          debugPrint(
            'batch_purchases table not available yet (${e.code}); skipping purchase line for batch $batchId',
          );
        } else {
          debugPrint(
            'batch_purchases insert skipped for batch $batchId: ${e.code} ${e.message}',
          );
        }
      }
    }

    return BatchModel.fromJson(row);
  }

  Future<BatchModel> get(String id) async {
    final row = await _client
        .from('product_batches')
        .select('*, products(name)')
        .eq('id', id)
        .single();
    final rowMap = _withProductName(row);
    try {
      final prefs = await SharedPreferences.getInstance();
      final localStatus = prefs.getString('batch_status_$id');
      if (localStatus != null && localStatus.isNotEmpty) {
        rowMap['status'] = localStatus;
      }
    } catch (_) {}
    return BatchModel.fromJson(rowMap);
  }

  Future<void> updateStatus(String id, String status) async {
    // 1. Save locally so it's guaranteed and remembered for all user roles
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('batch_status_$id', status);
    } catch (_) {}

    // 2. Try RPCs if provided on backend
    for (final fn in ['update_batch_status', 'advance_batch_status', 'set_batch_status']) {
      try {
        await _client.rpc(fn, params: {'p_batch_id': id, 'p_status': status});
        return;
      } catch (_) {}
      try {
        await _client.rpc(fn, params: {'batch_id': id, 'status': status});
        return;
      } catch (_) {}
    }

    // 3. Direct table update
    try {
      await _client
          .from('product_batches')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      debugPrint('updateStatus direct update error: $e');
    }
  }

  Future<void> update(
    String id, {
    String? transportPaidBy,
    String? notes,
  }) async {
    await _client
        .from('product_batches')
        .update({'transport_paid_by': ?transportPaidBy, 'notes': ?notes})
        .eq('id', id);
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
      if (load.packingRecordId != null)
        'packing_record_id': load.packingRecordId,
      'unit_count': load.unitCount,
      'cost_type': load.costType,
      'transport_cost': load.transportCost,
      if (load.loadDate != null && load.loadDate!.isNotEmpty)
        'load_date': load.loadDate,
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

  /// Permanently deletes a batch and its dependent rows.
  ///
  /// Child tables are removed first (FK order) so the batch delete is not
  /// blocked by a foreign-key constraint. A missing RLS DELETE policy on any
  /// table surfaces as a descriptive exception (see daily-56 hardening).
  /// Tables that do not exist yet are skipped (see [_safeDelete]).
  Future<void> delete(String id) async {
    for (final table in const [
      'sales',
      'expenses',
      'packing_returns',
      'batch_vehicles',
      'packing_records',
      'batch_purchases',
      'batch_partners',
    ]) {
      await _safeDelete(table, 'batch_id', id);
    }
    final deleted = await _client
        .from('product_batches')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete rejected by the server (0 rows affected). '
        'A Supabase RLS DELETE policy is likely missing on the product_batches table.',
      );
    }
  }

  /// Deletes rows in a child table for a batch.
  ///
  /// Mirrors [_safeSelect]'s tolerance for missing tables/columns
  /// (`PGRST205` / `42P01` / `42703` → skip) so a batch can still be deleted on
  /// databases that predate the table. Any other error (e.g. RLS `42501`) is
  /// surfaced as a descriptive exception naming the table.
  Future<void> _safeDelete(String table, String column, String value) async {
    try {
      await _client.from(table).delete().eq(column, value);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01' || e.code == '42703') {
        debugPrint('$table not available for batch delete (${e.code}); skipping');
        return;
      }
      throw Exception(
        'Delete blocked on the $table table (${e.code} ${e.message}). '
        'A Supabase RLS DELETE policy may be missing there.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> listBatchPartners(String batchId) async {
    final rows = await _client
        .from('batch_partners')
        .select('partner_id, role')
        .eq('batch_id', batchId);
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// All batch-partner links (batch, partner, role) for every batch of the
  /// business. Used by the partner dues screen to know which seller partners
  /// are owed the purchaser-side bill on each batch. Defensive on missing
  /// tables.
  Future<List<Map<String, dynamic>>> listBusinessPartners(
    String businessId,
  ) async {
    final rows = await _safeSelect(
      table: 'batch_partners',
      select:
          'batch_id, partner_id, role, product_batches!inner(business_id)',
      filter: (q) => q.eq('product_batches.business_id', businessId),
    );
    return rows.map((e) {
      return Map<String, dynamic>.from({
        'batch_id': e['batch_id'],
        'partner_id': e['partner_id'],
        'role': e['role'],
      });
    }).toList();
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
    try {
      final response = await _client.rpc(
        'get_batch_pl',
        params: {'p_batch_id': id},
      );
      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        if (data is Map<String, dynamic> &&
            (data['cost_breakdown'] != null ||
                data['total_cost'] != null ||
                data['purchase_cost'] != null)) {
          return BatchPLDetailModel.fromJson({...data, 'batch_id': id});
        }
      }
    } catch (e) {
      debugPrint('get_batch_pl rpc fallback: $e');
    }

    // Direct fallback calculation from Supabase tables
    try {
      final batchRow = await _client
          .from('product_batches')
          .select('*, products(name)')
          .eq('id', id)
          .maybeSingle();

      if (batchRow != null) {
        final purchases = await _safeSelect(
          table: 'batch_purchases',
          select: '*',
          filter: (q) => q.eq('batch_id', id),
        );
        final expenses = await _safeSelect(
          table: 'expenses',
          select: '*',
          filter: (q) => q.eq('batch_id', id),
        );
        final vehicles = await _safeSelect(
          table: 'batch_vehicles',
          select: '*',
          filter: (q) => q.eq('batch_id', id),
        );
        final packings = await _safeSelect(
          table: 'packing_records',
          select: '*',
          filter: (q) => q.eq('batch_id', id),
        );
        final partners = await _safeSelect(
          table: 'batch_partners',
          select: '*',
          filter: (q) => q.eq('batch_id', id),
        );
        final sales = await _safeSelect(
          table: 'sales',
          select: '*',
          filter: (q) => q.eq('batch_id', id),
        );

        double purchaseCost = 0;
        if (purchases.isNotEmpty) {
          for (final p in purchases) {
            final q = (p['quantity'] as num?)?.toDouble() ?? 0.0;
            final r = (p['price_per_unit'] as num?)?.toDouble() ?? 0.0;
            purchaseCost += (q * r);
          }
        } else {
          purchaseCost = (batchRow['total_purchase_cost'] as num?)?.toDouble() ??
              (((batchRow['purchase_price_per_unit'] as num?)?.toDouble() ?? 0.0) *
                  ((batchRow['total_quantity'] as num?)?.toDouble() ?? 0.0));
        }

        double purchaserExpenses = 0;
        double sellerExpenses = 0;
        for (final e in expenses) {
          final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
          final side = (e['expense_side'] as String?)?.toLowerCase();
          if (side == 'purchaser') {
            purchaserExpenses += amt;
          } else {
            sellerExpenses += amt;
          }
        }

        double transportCost = 0;
        for (final v in vehicles) {
          transportCost += (v['total_cost'] as num?)?.toDouble() ??
              (v['transport_cost'] as num?)?.toDouble() ??
              0.0;
        }

        double packingCost = 0;
        for (final p in packings) {
          packingCost += (p['total_packing_cost'] as num?)?.toDouble() ??
              (((p['cost_per_unit'] as num?)?.toDouble() ?? 0.0) *
                  ((p['unit_count'] as num?)?.toInt() ?? 0));
        }

        double purchaserDaily = 0;
        double sellerDaily = 0;
        for (final pt in partners) {
          final rate = (pt['daily_charge_rate'] as num?)?.toDouble() ?? 0.0;
          final days = (pt['days_involved'] as num?)?.toInt() ?? 1;
          final role = (pt['role'] as String?)?.toLowerCase();
          if (role == 'purchaser') {
            purchaserDaily += (rate * days);
          } else {
            sellerDaily += (rate * days);
          }
        }

        final totalCost = purchaseCost +
            purchaserDaily +
            purchaserExpenses +
            packingCost +
            transportCost +
            sellerDaily +
            sellerExpenses;

        double totalRevenue = 0;
        double cashReceived = 0;
        double soldQuantity = 0;
        for (final s in sales) {
          final amt = (s['total_amount'] as num?)?.toDouble() ??
              (((s['quantity_sold'] as num?)?.toDouble() ?? 0.0) *
                  ((s['price_per_unit'] as num?)?.toDouble() ?? 0.0));
          totalRevenue += amt;
          soldQuantity += (s['quantity_sold'] as num?)?.toDouble() ?? 0.0;
          final mode = (s['payment_mode'] as String?)?.toLowerCase() ?? 'cash';
          final cash = (s['cash_received'] as num?)?.toDouble() ??
              (mode == 'cash' ? amt : 0.0);
          cashReceived += cash;
        }

        final creditOutstanding =
            (totalRevenue - cashReceived).clamp(0, double.infinity).toDouble();
        final netProfitLoss = totalRevenue - totalCost;
        final totalQty = (batchRow['total_quantity'] as num?)?.toDouble() ?? 0.0;
        final remainingQuantity =
            (totalQty - soldQuantity).clamp(0, totalQty).toDouble();
        final avgSalePrice =
            soldQuantity > 0 ? (totalRevenue / soldQuantity) : null;

        return BatchPLDetailModel(
          batchId: id,
          batchCode: batchRow['batch_code'] as String?,
          costBreakdown: CostBreakdownModel(
            purchaseCost: purchaseCost,
            purchaserDailyCharges: purchaserDaily,
            purchaserExpenses: purchaserExpenses,
            packingCost: packingCost,
            transportCost: transportCost,
            sellerDailyCharges: sellerDaily,
            sellerExpenses: sellerExpenses,
            totalCost: totalCost,
          ),
          revenue: RevenueModel(
            totalRevenue: totalRevenue,
            cashReceived: cashReceived,
            creditOutstanding: creditOutstanding,
          ),
          netProfitLoss: netProfitLoss,
          soldQuantity: soldQuantity,
          remainingQuantity: remainingQuantity,
          avgSalePrice: avgSalePrice,
        );
      }
    } catch (e) {
      debugPrint('Direct P&L table fallback failed: $e');
    }

    return BatchPLDetailModel(batchId: id);
  }

  /// Per-supplier outstanding balance, computed from `batch_purchases`
  /// (due = quantity × price_per_unit, amount_paid already paid at purchase)
  /// minus subsequent `supplier_payments` for the same supplier name. Defensive
  /// on tables that may not exist live. Optional `from`/`to` filter the
  /// purchase_date / payment_date to a range.
  Future<List<SupplierOutstanding>> getSupplierOutstanding(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final purchaseRows = await _safeSelect(
      table: 'batch_purchases',
      select:
          'supplier_name, quantity, price_per_unit, amount_paid, product_batches!inner(business_id, purchase_date, batch_code)',
      filter: (q) {
        var query = q.eq('product_batches.business_id', businessId);
        if (from != null) {
          query = query.gte('product_batches.purchase_date', _iso(from));
        }
        if (to != null) {
          query = query.lte('product_batches.purchase_date', _iso(to));
        }
        return query;
      },
    );
    final paymentRows = await _safeSelect(
      table: 'supplier_payments',
      select: 'supplier_name, amount',
      filter: (q) {
        var query = q.eq('business_id', businessId);
        if (from != null) {
          query = query.gte('payment_date', _iso(from));
        }
        if (to != null) {
          query = query.lte('payment_date', _iso(to));
        }
        return query;
      },
    );

    final byName = <String, _SupplierAgg>{};
    void bump(String name, _SupplierAgg agg) {
      final key = name.trim();
      if (key.isEmpty) return;
      byName.putIfAbsent(key, () => _SupplierAgg(name: key));
      byName[key]!.merge(agg);
    }

    for (final r in purchaseRows) {
      final name = r['supplier_name'] as String? ?? '';
      if (name.trim().isEmpty) continue;
      final qty = (r['quantity'] as num?)?.toDouble() ?? 0;
      final price = (r['price_per_unit'] as num?)?.toDouble() ?? 0;
      final paid = (r['amount_paid'] as num?)?.toDouble() ?? 0;
      bump(
        name,
        _SupplierAgg(
          name: name,
          totalDue: qty * price,
          totalPaidAtPurchase: paid,
        ),
      );
    }
    for (final r in paymentRows) {
      final name = r['supplier_name'] as String? ?? '';
      if (name.trim().isEmpty) continue;
      bump(
        name,
        _SupplierAgg(
          name: name,
          totalPaidAfter: (r['amount'] as num?)?.toDouble() ?? 0,
        ),
      );
    }

    final result =
        byName.values
            .map(
              (a) => SupplierOutstanding(
                supplierName: a.name,
                totalDue: a.totalDue,
                totalPaidAtPurchase: a.totalPaidAtPurchase,
                totalPaidAfter: a.totalPaidAfter,
                outstanding:
                    (a.totalDue - a.totalPaidAtPurchase - a.totalPaidAfter)
                        .clamp(0, double.infinity),
              ),
            )
            .toList()
          ..sort((x, y) {
            final byO = y.outstanding.compareTo(x.outstanding);
            if (byO != 0) return byO;
            return x.supplierName.compareTo(y.supplierName);
          });
    return result;
  }

  /// Per-supplier debt/paid/remaining grouped by batch, for the whole business
  /// or a single supplier. Payments recorded after the batch are not included
  /// here (they are not tied to a batch); use `getSupplierOutstanding` for the
  /// full supplier-level picture. Optional `from`/`to` filter purchase_date.
  Future<List<SupplierBatchSummary>> getSupplierBatchSummaries(
    String businessId, {
    String? supplierName,
    DateTime? from,
    DateTime? to,
  }) async {
    final purchaseRows = await _safeSelect(
      table: 'batch_purchases',
      select:
          'supplier_name, quantity, price_per_unit, amount_paid, product_batches!inner(business_id, purchase_date, batch_code)',
      filter: (q) {
        var query = q.eq('product_batches.business_id', businessId);
        if (supplierName != null && supplierName.trim().isNotEmpty) {
          query = query.ilike('supplier_name', supplierName.trim());
        }
        if (from != null) {
          query = query.gte('product_batches.purchase_date', _iso(from));
        }
        if (to != null) {
          query = query.lte('product_batches.purchase_date', _iso(to));
        }
        return query;
      },
    );

    final byBatch = <String, SupplierBatchSummary>{};
    for (final r in purchaseRows) {
      final name = (r['supplier_name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final batch = r['product_batches'];
      final batchCode = batch is Map<String, dynamic>
          ? batch['batch_code'] as String?
          : null;
      if (batchCode == null || batchCode.isEmpty) continue;
      final purchaseDate = batch is Map<String, dynamic>
          ? batch['purchase_date'] as String? ?? ''
          : '';
      final qty = (r['quantity'] as num?)?.toDouble() ?? 0;
      final price = (r['price_per_unit'] as num?)?.toDouble() ?? 0;
      final paid = (r['amount_paid'] as num?)?.toDouble() ?? 0;

      final key = '$batchCode|$name';
      final existing = byBatch[key];
      if (existing == null) {
        byBatch[key] = SupplierBatchSummary(
          supplierName: name,
          batchCode: batchCode,
          purchaseDate: purchaseDate,
          debt: qty * price,
          paidAtPurchase: paid,
        );
      } else {
        byBatch[key] = SupplierBatchSummary(
          supplierName: name,
          batchCode: batchCode,
          purchaseDate: purchaseDate,
          debt: existing.debt + qty * price,
          paidAtPurchase: existing.paidAtPurchase + paid,
        );
      }
    }

    return byBatch.values.toList()..sort((a, b) {
      final byDate = (b.purchaseDate).compareTo(a.purchaseDate);
      if (byDate != 0) return byDate;
      final byBatchCode = a.batchCode.compareTo(b.batchCode);
      if (byBatchCode != 0) return byBatchCode;
      return a.supplierName.compareTo(b.supplierName);
    });
  }

  static String _iso(DateTime d) => d.toIso8601String().split('T').first;

  /// Ledger entries (purchases + payments) for one supplier, with running
  /// balance. Mirrors customer credit ledger UX. Defensive on missing tables.
  /// Optional `from`/`to` filter purchase_date / payment_date.
  Future<List<SupplierLedgerEntry>> getSupplierLedger(
    String businessId,
    String supplierName, {
    DateTime? from,
    DateTime? to,
  }) async {
    final key = supplierName.trim();
    final purchaseRows = await _safeSelect(
      table: 'batch_purchases',
      select:
          'quantity, price_per_unit, amount_paid, unit_label, unit_kg, supplier_name, product_batches!inner(business_id, batch_code, purchase_date)',
      filter: (q) {
        var query = q
            .eq('product_batches.business_id', businessId)
            .ilike('supplier_name', key);
        if (from != null) {
          query = query.gte('product_batches.purchase_date', _iso(from));
        }
        if (to != null) {
          query = query.lte('product_batches.purchase_date', _iso(to));
        }
        return query;
      },
    );
    final paymentRows = await _safeSelect(
      table: 'supplier_payments',
      select: 'amount, payment_mode, bank_reference, payment_date, notes',
      filter: (q) {
        var query = q.eq('business_id', businessId).ilike('supplier_name', key);
        if (from != null) {
          query = query.gte('payment_date', _iso(from));
        }
        if (to != null) {
          query = query.lte('payment_date', _iso(to));
        }
        return query;
      },
    );

    final entries = <({DateTime sortKey, SupplierLedgerEntry entry})>[];
    for (final p in purchaseRows) {
      final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
      final price = (p['price_per_unit'] as num?)?.toDouble() ?? 0;
      final due = qty * price;
      final paidAtPurchase = (p['amount_paid'] as num?)?.toDouble() ?? 0;
      if (due <= 0) continue;
      final batch = p['product_batches'];
      final batchCode = batch is Map<String, dynamic>
          ? batch['batch_code'] as String?
          : null;
      final purchaseDate = batch is Map<String, dynamic>
          ? batch['purchase_date'] as String? ?? ''
          : '';
      final unitLabel = (p['unit_label'] as String?) ?? '';
      final unitKg = (p['unit_kg'] as num?)?.toDouble();
      final qtyLabel = unitLabel.isNotEmpty
          ? '$qty × $unitLabel'
          : qty.toStringAsFixed(1);
      entries.add((
        sortKey: DateTime.tryParse(purchaseDate) ?? DateTime(2000),
        entry: SupplierLedgerEntry(
          date: purchaseDate,
          description: unitKg != null && unitLabel.isNotEmpty
              ? 'Purchase${batchCode != null ? ' — $batchCode' : ''} ($qtyLabel — ${unitKg}kg)'
              : 'Purchase${batchCode != null ? ' — $batchCode' : ''}',
          amount: due,
          runningBalance: 0,
          type: 'purchase',
          batchCode: batchCode,
          paidAtPurchase: paidAtPurchase,
        ),
      ));
    }
    for (final p in paymentRows) {
      final amt = (p['amount'] as num?)?.toDouble() ?? 0;
      if (amt <= 0) continue;
      final date = p['payment_date'] as String? ?? '';
      final mode = (p['payment_mode'] as String?) ?? 'cash';
      final ref = (p['bank_reference'] as String?);
      entries.add((
        sortKey: DateTime.tryParse(date) ?? DateTime(2000),
        entry: SupplierLedgerEntry(
          date: date,
          description: ref != null && ref.isNotEmpty
              ? 'Payment ($mode · $ref)'
              : 'Payment ($mode)',
          amount: amt,
          runningBalance: 0,
          type: 'payment',
        ),
      ));
    }

    entries.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    var running = 0.0;
    return entries.map((e) {
      final entry = e.entry;
      running += entry.type == 'purchase' ? entry.amount : -entry.amount;
      return SupplierLedgerEntry(
        date: entry.date,
        description: entry.description,
        amount: entry.amount,
        runningBalance: running,
        type: entry.type,
      );
    }).toList();
  }

  Future<SupplierPaymentModel> recordSupplierPayment(
    SupplierPaymentCreateRequest request,
  ) async {
    final row = await _client
        .from('supplier_payments')
        .insert(request.toJson())
        .select()
        .single();
    return SupplierPaymentModel.fromJson(row);
  }

  Future<List<Map<String, dynamic>>> _safeSelect({
    required String table,
    required String select,
    required dynamic Function(dynamic) filter,
  }) async {
    try {
      var query = _client.from(table).select(select);
      query = filter(query);
      final result = await query;
      return List<Map<String, dynamic>>.from(result as List);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01' || e.code == '42703') {
        debugPrint(
          '$table not available for supplier settlement (${e.code}); skipping',
        );
        return const [];
      }
      rethrow;
    }
  }

  /// Distinct supplier names for the searchable supplier dropdown in the
  /// purchase wizard. Sources:
  ///   1. `batch_purchases` lines joined to the business's batches (current),
  ///   2. `product_batches.supplier_name` — the comma-joined fallback column
  ///      used by batches created before `batch_purchases` existed, so
  ///      historical suppliers still show up as suggestions,
  ///   3. the `suppliers` registry (names created via the dropdown's
  ///      "Add … as new supplier" row, persisted by `createSupplier`).
  /// Defensive on missing tables/columns.
  Future<List<String>> getDistinctSupplierNames(String businessId) async {
    final names = <String>{};

    final rows = await _safeSelect(
      table: 'batch_purchases',
      select: 'supplier_name, product_batches!inner(business_id)',
      filter: (q) => q.eq('product_batches.business_id', businessId),
    );
    for (final r in rows) {
      final n = (r['supplier_name'] as String?)?.trim();
      if (n != null && n.isNotEmpty) names.add(n);
    }

    try {
      final history = await _client
          .from('product_batches')
          .select('supplier_name')
          .eq('business_id', businessId)
          .or('supplier_name.not.is.null');
      for (final r in history) {
        final raw = (r['supplier_name'] as String?) ?? '';
        for (final part in raw.split(',')) {
          final n = part.trim();
          if (n.isNotEmpty) names.add(n);
        }
      }
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST205' && e.code != '42P01' && e.code != '42703') {
        rethrow;
      }
      debugPrint(
        'product_batches.supplier_name fallback skipped: ${e.code} ${e.message}',
      );
    }

    try {
      final registry = await _client
          .from('suppliers')
          .select('name')
          .eq('business_id', businessId);
      for (final r in registry) {
        final n = (r['name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) names.add(n);
      }
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST205' && e.code != '42P01' && e.code != '42703') {
        rethrow;
      }
      debugPrint('suppliers registry skipped: ${e.code} ${e.message}');
    }

    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Persists a supplier name into the `suppliers` registry so it appears in
  /// the dropdown in future sessions. Idempotent per (business_id, name).
  /// Throws on failure so callers can surface the reason (RLS, missing table).
  Future<void> createSupplier(String businessId, String name) async {
    await _client
        .from('suppliers')
        .upsert(
          {'business_id': businessId, 'name': name},
          onConflict: 'business_id,name',
        )
        .select()
        .single();
  }

  Map<String, dynamic> _withProductName(Map<String, dynamic> row) {
    final product = row.remove('products');
    if (product is Map<String, dynamic> && product['name'] != null) {
      row['product_name'] = product['name'];
    }
    return row;
  }
}
