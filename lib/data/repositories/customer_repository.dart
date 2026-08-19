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
    final customers = rows.map(CustomerModel.fromJson).toList();
    final totals = await _liveCustomerTotals(
      customers.map((c) => c.id).toList(),
    );
    return customers
        .map(
          (c) => CustomerModel(
            id: c.id,
            businessId: c.businessId,
            fullName: c.fullName,
            phone: c.phone,
            city: c.city,
            shopName: c.shopName,
            totalPurchased: totals[c.id]?.purchased ?? 0.0,
            totalPaid: totals[c.id]?.paid ?? 0.0,
            outstandingBalance: totals[c.id]?.outstanding ?? 0.0,
            isArchived: c.isArchived,
          ),
        )
        .toList();
  }

  /// Live purchased/paid/outstanding totals per customer, summed straight
  /// from `sales` — the ledger `recordPayment`'s FIFO allocation keeps
  /// `credit_amount`/`cash_received` accurate on every partial payment, and
  /// a sale's own `cash_received` already captures cash collected at the
  /// time of a partial-credit sale. `customers.outstanding_balance` /
  /// `.total_paid` / `.total_purchased` are DB-maintained caches that drift
  /// out of sync (e.g. a partial payment made at sale time never touches
  /// `customer_payments`, so those caches miss it), so every read of a
  /// customer's credit standing in the app must go through this instead of
  /// trusting those columns.
  Future<Map<String, ({double purchased, double paid, double outstanding})>>
  _liveCustomerTotals(List<String> customerIds) async {
    if (customerIds.isEmpty) return const {};
    final rows = await _client
        .from('sales')
        .select('customer_id, total_amount, cash_received, credit_amount')
        .inFilter('customer_id', customerIds);
    final totals = <String, ({double purchased, double paid, double outstanding})>{};
    for (final r in rows) {
      final id = r['customer_id'] as String?;
      if (id == null) continue;
      final total = (r['total_amount'] as num?)?.toDouble() ?? 0.0;
      final cash = (r['cash_received'] as num?)?.toDouble() ?? 0.0;
      final credit = (r['credit_amount'] as num?)?.toDouble() ?? 0.0;
      final existing = totals[id] ?? (purchased: 0.0, paid: 0.0, outstanding: 0.0);
      totals[id] = (
        purchased: existing.purchased + total,
        paid: existing.paid + cash,
        outstanding: existing.outstanding + (credit > 0.001 ? credit : 0.0),
      );
    }
    return totals;
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
        .select('sale_date, total_amount, cash_received, quantity_sold, product_batches(batch_code)')
        .eq('customer_id', customerId);
    final payments = await _client
        .from('customer_payments')
        .select('payment_date, amount')
        .eq('customer_id', customerId);

    final entries = <({DateTime sortKey, CustomerLedgerEntry entry})>[];
    for (final s in sales) {
      final batch = s['product_batches'];
      final batchCode = batch is Map<String, dynamic> ? batch['batch_code'] : null;
      final saleDate = s['sale_date'] as String? ?? '';
      entries.add((
        sortKey: DateTime.tryParse(saleDate) ?? DateTime(2000),
        entry: CustomerLedgerEntry(
          date: saleDate,
          description: 'Sale${batchCode != null ? ' — $batchCode' : ''}',
          amount: (s['total_amount'] as num?)?.toDouble() ?? 0,
          runningBalance: 0,
          type: 'sale',
        ),
      ));
      // Cash paid at the time of a (partial-)credit sale never creates a
      // `customer_payments` row — surface it as its own line here, or it
      // silently vanishes from the transaction history and the running
      // balance overstates what's still owed.
      final cashAtSale = (s['cash_received'] as num?)?.toDouble() ?? 0.0;
      if (cashAtSale > 0.001) {
        entries.add((
          sortKey: DateTime.tryParse(saleDate) ?? DateTime(2000),
          entry: CustomerLedgerEntry(
            date: saleDate,
            description: 'Cash received at sale',
            amount: cashAtSale,
            runningBalance: 0,
            type: 'payment',
          ),
        ));
      }
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
    if (payment.notes == null ||
        !payment.notes!.startsWith('Collected on sale')) {
      try {
        var remainingPayment = payment.amount;
        if (remainingPayment > 0) {
          final openSales = await _client
              .from('sales')
              .select('id, credit_amount, cash_received, payment_mode, sale_date')
              .eq('customer_id', customerId);

          final salesList = List<Map<String, dynamic>>.from(openSales);
          // Filter to only open credit sales in memory
          final openCreditSales = salesList
              .where(
                (s) =>
                    ((s['credit_amount'] as num?)?.toDouble() ?? 0.0) > 0.001,
              )
              .toList();

          openCreditSales.sort((a, b) {
            final dateA = a['sale_date']?.toString() ?? '';
            final dateB = b['sale_date']?.toString() ?? '';
            return dateA.compareTo(dateB);
          });

          for (final saleMap in openCreditSales) {
            if (remainingPayment <= 0.001) break;
            final saleId = saleMap['id']?.toString() ?? '';
            if (saleId.isEmpty) continue;

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
        // Non-critical if auto-allocation fails
      }
    }

    return PaymentModel.fromJson(row);
  }

  /// Synchronizes past customer payments with open credit sales so historical
  /// or unapplied payments clear their matching sales invoices.
  Future<void> reconcileCustomerSales(String customerId) async {
    try {
      final payments = await _client
          .from('customer_payments')
          .select('amount, notes')
          .eq('customer_id', customerId);

      var totalGeneralPaid = 0.0;
      for (final p in payments) {
        final notes = p['notes']?.toString() ?? '';
        if (!notes.startsWith('Collected on sale')) {
          totalGeneralPaid += (p['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (totalGeneralPaid <= 0) return;

      final sales = await _client
          .from('sales')
          .select('id, total_amount, cash_received, credit_amount, sale_date')
          .eq('customer_id', customerId);

      final salesList = List<Map<String, dynamic>>.from(sales);
      salesList.sort((a, b) {
        final dateA = a['sale_date']?.toString() ?? '';
        final dateB = b['sale_date']?.toString() ?? '';
        return dateA.compareTo(dateB);
      });

      var remainingToApply = totalGeneralPaid;
      for (final s in salesList) {
        if (remainingToApply <= 0.001) break;
        final saleId = s['id']?.toString() ?? '';
        final currentCredit = (s['credit_amount'] as num?)?.toDouble() ?? 0.0;
        final currentCash = (s['cash_received'] as num?)?.toDouble() ?? 0.0;

        if (currentCredit <= 0.001) continue;

        final toApply = remainingToApply < currentCredit
            ? remainingToApply
            : currentCredit;
        final newCredit = (currentCredit - toApply).clamp(0.0, double.infinity);
        final newCash = currentCash + toApply;
        remainingToApply -= toApply;

        await _client
            .from('sales')
            .update({
              'credit_amount': newCredit,
              'cash_received': newCash,
              if (newCredit <= 0.001) 'payment_mode': 'cash',
            })
            .eq('id', saleId);
      }
    } catch (_) {}
  }
}
