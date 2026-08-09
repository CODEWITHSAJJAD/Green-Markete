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
    return PaymentModel.fromJson(row);
  }
}
