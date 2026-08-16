import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';

class CustomerRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<CustomerModel>> list(
    String businessId, {
    String? search,
    bool includeArchived = false,
  }) async {
    try {
      return await _listInternal(businessId, search: search, includeArchived: includeArchived);
    } on PostgrestException catch (e) {
      if (includeArchived || e.code != '42703') rethrow;
      // Live DB's customers table lacks the is_archived column; retry without
      // the archive filter so the customer list and sell flow keep working.
      return _listInternal(businessId, search: search, includeArchived: true);
    }
  }

  Future<List<CustomerModel>> _listInternal(
    String businessId, {
    String? search,
    bool includeArchived = false,
  }) async {
    var query = _client
        .from('customers')
        .select()
        .eq('business_id', businessId);
    if (!includeArchived) {
      query = query.or('is_archived.is.null,is_archived.eq.false');
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'full_name.ilike.%$search%,phone.ilike.%$search%,shop_name.ilike.%$search%',
      );
    }
    final rows = await query.order('full_name');
    return rows.map(CustomerModel.fromJson).toList();
  }

  /// Returns the ids of customers shared with/from this business, plus whether
  /// a customer-sharing table exists at all.
  ///
  /// The live schema has no customer-sharing table yet, so this is strictly
  /// defensive: it probes two plausible `customer_shares` column shapes and
  /// returns an empty list + `supported: false` on any error. Callers must
  /// never treat a missing table as a hard failure.
  Future<({List<String> ids, bool supported})> listSharedCustomerIds(
    String businessId,
  ) async {
    const notSupported = (ids: <String>[], supported: false);
    try {
      final rows = await _client
          .from('customer_shares')
          .select('customer_id')
          .eq('business_id', businessId);
      return (
        ids: rows.map((r) => r['customer_id'] as String).toList(),
        supported: true,
      );
    } on PostgrestException {
      // Table or column missing — try the "shared with" shape below.
    }
    try {
      final rows = await _client
          .from('customer_shares')
          .select('customer_id')
          .eq('shared_with_business_id', businessId);
      return (
        ids: rows.map((r) => r['customer_id'] as String).toList(),
        supported: true,
      );
    } catch (_) {
      return notSupported;
    }
  }

  Future<CustomerModel> archive(String id) async {
    final row = await _client
        .from('customers')
        .update({'is_archived': true})
        .eq('id', id)
        .select()
        .single();
    return CustomerModel.fromJson(row);
  }

  Future<CustomerModel> unarchive(String id) async {
    final row = await _client
        .from('customers')
        .update({'is_archived': false})
        .eq('id', id)
        .select()
        .single();
    return CustomerModel.fromJson(row);
  }

  Future<CustomerModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from('customers')
        .insert({
          'business_id': data['business_id'],
          'full_name': data['full_name'],
          'phone': data['phone'],
          'city': data['city'],
          'shop_name': data['shop_name'],
        })
        .select()
        .single();
    return CustomerModel.fromJson(row);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from('customers')
        .update({
          if (data['full_name'] != null) 'full_name': data['full_name'],
          if (data['phone'] != null) 'phone': data['phone'],
          if (data['city'] != null) 'city': data['city'],
          if (data['shop_name'] != null) 'shop_name': data['shop_name'],
        })
        .eq('id', id)
        .select()
        .single();
    return CustomerModel.fromJson(row);
  }

  Future<List<CustomerLedgerEntry>> getLedger(String customerId) async {
    final sales = await _client
        .from('sales')
        .select('sale_date, total_amount, quantity_sold, product_batches(batch_code)')
        .eq('customer_id', customerId);
    final payments = await _client
        .from('customer_payments')
        .select('payment_date, amount')
        .eq('customer_id', customerId);

    final entries = <({DateTime sortKey, CustomerLedgerEntry entry})>[];
    for (final s in sales) {
      final batch = s['product_batches'];
      final batchCode = batch is Map<String, dynamic> ? batch['batch_code'] : null;
      entries.add((
        sortKey: DateTime.tryParse(s['sale_date'] as String? ?? '') ?? DateTime(2000),
        entry: CustomerLedgerEntry(
          date: s['sale_date'] as String? ?? '',
          description: 'Sale${batchCode != null ? ' — $batchCode' : ''}',
          amount: (s['total_amount'] as num?)?.toDouble() ?? 0,
          runningBalance: 0,
          type: 'sale',
        ),
      ));
    }
    for (final p in payments) {
      entries.add((
        sortKey: DateTime.tryParse(p['payment_date'] as String? ?? '') ?? DateTime(2000),
        entry: CustomerLedgerEntry(
          date: p['payment_date'] as String? ?? '',
          description: 'Payment received',
          amount: (p['amount'] as num?)?.toDouble() ?? 0,
          runningBalance: 0,
          type: 'payment',
        ),
      ));
    }

    entries.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    var running = 0.0;
    return entries.map((e) {
      final entry = e.entry;
      running += entry.type == 'sale' ? entry.amount : -entry.amount;
      return CustomerLedgerEntry(
        date: entry.date,
        description: entry.description,
        amount: entry.amount,
        runningBalance: running,
        type: entry.type,
      );
    }).toList();
  }

  Future<PaymentModel> recordPayment(
    String customerId,
    PaymentCreateRequest payment,
  ) async {
    final row = await _client
        .from('customer_payments')
        .insert({
          'customer_id': customerId,
          'business_id': payment.businessId,
          'amount': payment.amount,
          'payment_mode': payment.paymentMode,
          'bank_reference': payment.bankReference,
          'payment_date': payment.paymentDate,
          'received_by': payment.receivedBy ?? _client.auth.currentUser?.id,
          'notes': payment.notes,
        })
        .select()
        .single();

    // Auto-reconcile open sales with credit for this customer (FIFO order)
    try {
      var remainingPayment = payment.amount;
      if (remainingPayment > 0) {
        final openSales = await _client
            .from('sales')
            .select()
            .eq('customer_id', customerId)
            .gt('credit_amount', 0)
            .order('sale_date', ascending: true);

        for (final saleMap in openSales) {
          if (remainingPayment <= 0.001) break;
          final saleId = saleMap['id'] as String;
          final currentCredit =
              (saleMap['credit_amount'] as num?)?.toDouble() ?? 0.0;
          final currentCash =
              (saleMap['cash_received'] as num?)?.toDouble() ?? 0.0;

          if (currentCredit <= 0.001) continue;

          final toDeduct = remainingPayment < currentCredit
              ? remainingPayment
              : currentCredit;
          final newCredit = (currentCredit - toDeduct).clamp(
            0.0,
            double.infinity,
          );
          final newCash = currentCash + toDeduct;
          remainingPayment -= toDeduct;

          await _client
              .from('sales')
              .update({
                'credit_amount': newCredit,
                'cash_received': newCash,
                if (newCredit <= 0.001) 'payment_mode': payment.paymentMode,
              })
              .eq('id', saleId);
        }
      }
    } catch (_) {
      // Non-critical if auto-allocation fails on non-standard schema
    }

    return PaymentModel.fromJson(row);
  }
}
