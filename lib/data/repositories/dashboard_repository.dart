import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/batch_model.dart';
import '../models/report_model.dart';

class DashboardRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  static const _cacheKey = 'dashboard_summary_cache';

  Future<DashboardSummaryModel> getSummary(String businessId) async {
    try {
      final summary = await _fetchSummary(businessId);
      unawaited(_writeCache(summary));
      return summary;
    } catch (_) {
      final cached = await _readCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<DashboardSummaryModel> _fetchSummary(String businessId) async {
    final now = DateTime.now();
    final todayIso = DateTime(now.year, now.month, now.day).toIso8601String();

    // 1. Fetch batches belonging to this business
    final batchesRows = await _client
        .from('product_batches')
        .select('*, products(name)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    final batchList = (batchesRows as List);
    final batchIds = batchList.map((b) => b['id'].toString()).toList();
    final totalBatches = batchList.length;
    final activeBatches = batchList
        .where((b) => (b['status'] as String?)?.toLowerCase() != 'closed')
        .length;
    final sellingBatches = batchList
        .where((b) => (b['status'] as String?)?.toLowerCase() == 'selling')
        .length;

    // 2. Fetch sales for these batches
    double totalRevenue = 0;
    double todayRevenue = 0;
    int todaySalesCount = 0;

    if (batchIds.isNotEmpty) {
      try {
        final salesRows = await _client
            .from('sales')
            .select('total_amount, sale_date')
            .filter('batch_id', 'in', batchIds);

        for (final s in (salesRows as List)) {
          final amt = (s['total_amount'] as num?)?.toDouble() ?? 0.0;
          totalRevenue += amt;
          final sDate = s['sale_date'] as String?;
          if (sDate != null && sDate.compareTo(todayIso) >= 0) {
            todayRevenue += amt;
            todaySalesCount++;
          }
        }
      } catch (_) {}
    }

    // 3. Profit & Loss computation
    double totalCost = 0;
    double totalProfitLoss = 0;

    try {
      final rpcRes = await _client.rpc(
        'get_business_pl_summary',
        params: {
          'p_business_id': businessId,
          'p_from_date': '1900-01-01',
          'p_to_date': '2100-01-01',
        },
      );
      final data = rpcRes is Map<String, dynamic> ? rpcRes['data'] : rpcRes;
      if (data is Map<String, dynamic>) {
        final rpcRev = (data['total_revenue'] as num?)?.toDouble() ?? 0;
        if (rpcRev > 0) totalRevenue = rpcRev;
        totalCost = (data['total_cost'] as num?)?.toDouble() ?? 0;
        totalProfitLoss = (data['total_profit_loss'] as num?)?.toDouble() ?? (totalRevenue - totalCost);
      }
    } catch (_) {}

    // Fallback cost aggregation if RPC returned 0
    if (totalCost == 0 && batchIds.isNotEmpty) {
      try {
        final expRows = await _client
            .from('expenses')
            .select('amount')
            .filter('batch_id', 'in', batchIds);
        final expSum = (expRows as List).fold<double>(
          0,
          (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
        );

        final purchRows = await _client
            .from('batch_purchases')
            .select('quantity, price_per_unit')
            .filter('batch_id', 'in', batchIds);
        final purchSum = (purchRows as List).fold<double>(
          0,
          (sum, row) =>
              sum +
              (((row['quantity'] as num?)?.toDouble() ?? 0) *
                  ((row['price_per_unit'] as num?)?.toDouble() ?? 0)),
        );

        totalCost = expSum + purchSum;
        totalProfitLoss = totalRevenue - totalCost;
      } catch (_) {}
    }

    // 4. Products count
    int totalProducts = 0;
    try {
      final prodRows = await _client
          .from('products')
          .select('id')
          .eq('business_id', businessId);
      totalProducts = (prodRows as List).length;
    } catch (_) {}

    // 5. Customers and Outstanding Credit
    int totalCustomers = 0;
    int customersWithCredit = 0;
    double outstandingCredit = 0;
    try {
      final custRows = await _client
          .from('customers')
          .select('id, outstanding_balance')
          .eq('business_id', businessId);
      final custList = (custRows as List);
      totalCustomers = custList.length;
      for (final c in custList) {
        final bal = (c['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
        outstandingCredit += bal;
        if (bal > 0) customersWithCredit++;
      }
    } catch (_) {}

    // 6. Supplier Payables
    double supplierPayables = 0;
    try {
      final purchRows = await _client
          .from('batch_purchases')
          .select('quantity, price_per_unit, amount_paid')
          .filter('batch_id', 'in', batchIds);
      final purchList = (purchRows as List);
      for (final p in purchList) {
        final totalDue = (((p['quantity'] as num?)?.toDouble() ?? 0) *
            ((p['price_per_unit'] as num?)?.toDouble() ?? 0));
        final paid = (p['amount_paid'] as num?)?.toDouble() ?? 0;
        final due = (totalDue - paid).clamp(0, double.infinity).toDouble();
        supplierPayables += due;
      }
    } catch (_) {}

    // 7. Recent Batches
    final recentBatches = batchList
        .take(5)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .map(_withProductName)
        .map(BatchModel.fromJson)
        .toList();

    return DashboardSummaryModel(
      todaySales: todayRevenue,
      todayRevenue: todayRevenue,
      todaySalesCount: todaySalesCount,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfitLoss: totalProfitLoss,
      activeBatches: activeBatches,
      sellingBatches: sellingBatches,
      totalBatches: totalBatches,
      totalProducts: totalProducts,
      totalCustomers: totalCustomers,
      customersWithCreditCount: customersWithCredit,
      outstandingCredit: outstandingCredit,
      supplierPayables: supplierPayables,
      recentBatches: recentBatches,
    );
  }

  Map<String, dynamic> _withProductName(Map<String, dynamic> row) {
    final product = row.remove('products');
    if (product is Map<String, dynamic> && product['name'] != null) {
      row['product_name'] = product['name'];
    }
    return row;
  }

  Future<void> _writeCache(DashboardSummaryModel summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'today_sales': summary.todaySales,
        'today_revenue': summary.todayRevenue,
        'today_sales_count': summary.todaySalesCount,
        'total_revenue': summary.totalRevenue,
        'total_cost': summary.totalCost,
        'total_profit_loss': summary.totalProfitLoss,
        'active_batches': summary.activeBatches,
        'selling_batches': summary.sellingBatches,
        'total_batches': summary.totalBatches,
        'total_products': summary.totalProducts,
        'total_customers': summary.totalCustomers,
        'customers_with_credit_count': summary.customersWithCreditCount,
        'outstanding_credit': summary.outstandingCredit,
        'supplier_payables': summary.supplierPayables,
        'saved_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<DashboardSummaryModel?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DashboardSummaryModel(
        todaySales: (map['today_sales'] as num?)?.toDouble() ?? 0,
        todayRevenue: (map['today_revenue'] as num?)?.toDouble() ?? 0,
        todaySalesCount: (map['today_sales_count'] as num?)?.toInt() ?? 0,
        totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0,
        totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
        totalProfitLoss: (map['total_profit_loss'] as num?)?.toDouble() ?? 0,
        activeBatches: (map['active_batches'] as num?)?.toInt() ?? 0,
        sellingBatches: (map['selling_batches'] as num?)?.toInt() ?? 0,
        totalBatches: (map['total_batches'] as num?)?.toInt() ?? 0,
        totalProducts: (map['total_products'] as num?)?.toInt() ?? 0,
        totalCustomers: (map['total_customers'] as num?)?.toInt() ?? 0,
        customersWithCreditCount: (map['customers_with_credit_count'] as num?)?.toInt() ?? 0,
        outstandingCredit: (map['outstanding_credit'] as num?)?.toDouble() ?? 0,
        supplierPayables: (map['supplier_payables'] as num?)?.toDouble() ?? 0,
        recentBatches: const [],
      );
    } catch (_) {
      return null;
    }
  }
}
