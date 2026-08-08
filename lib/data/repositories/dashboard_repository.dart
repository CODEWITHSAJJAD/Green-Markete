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
    final todayStart = DateTime.now();
    final todayIso = DateTime(todayStart.year, todayStart.month, todayStart.day)
        .toIso8601String();

    final todaySales = await _client
        .from('sales')
        .select('total_amount, product_batches!inner(business_id)')
        .eq('product_batches.business_id', businessId)
        .gte('sale_date', todayIso);

    final batchesCount = await _client.from('product_batches').count();
    final totalBatches = batchesCount;

    final activeBatches = await _client
        .from('product_batches')
        .count()
        .not('status', 'eq', 'closed');

    final totalProducts = await _client.from('products').count();

    final totalCustomers = await _client.from('customers').count();

    final creditRows = await _client
        .from('customers')
        .select('outstanding_balance')
        .eq('business_id', businessId);
    final outstandingCredit = creditRows.fold<double>(
      0,
      (sum, row) => sum + ((row['outstanding_balance'] as num?)?.toDouble() ?? 0),
    );

    final recentRows = await _client
        .from('product_batches')
        .select('*, products(name)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(5);
    final recentBatches = recentRows.map(_withProductName).map(BatchModel.fromJson).toList();

    final todayRevenue = todaySales.fold<double>(
      0,
      (sum, row) => sum + ((row['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return DashboardSummaryModel(
      todaySales: todayRevenue,
      todayRevenue: todayRevenue,
      activeBatches: activeBatches,
      totalBatches: totalBatches,
      totalProducts: totalProducts,
      totalCustomers: totalCustomers,
      outstandingCredit: outstandingCredit,
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
        'active_batches': summary.activeBatches,
        'total_batches': summary.totalBatches,
        'total_products': summary.totalProducts,
        'total_customers': summary.totalCustomers,
        'outstanding_credit': summary.outstandingCredit,
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
        todayRevenue: (map['today_sales'] as num?)?.toDouble() ?? 0,
        activeBatches: (map['active_batches'] as num?)?.toInt() ?? 0,
        totalBatches: (map['total_batches'] as num?)?.toInt() ?? 0,
        totalProducts: (map['total_products'] as num?)?.toInt() ?? 0,
        totalCustomers: (map['total_customers'] as num?)?.toInt() ?? 0,
        outstandingCredit: (map['outstanding_credit'] as num?)?.toDouble() ?? 0,
        recentBatches: const [],
      );
    } catch (_) {
      return null;
    }
  }
}
