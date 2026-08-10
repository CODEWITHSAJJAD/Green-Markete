import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/green_card.dart';
import 'record_supplier_payment_page.dart';

class SupplierLedgerPage extends StatefulWidget {
  final String supplierName;
  const SupplierLedgerPage({super.key, required this.supplierName});

  @override
  State<SupplierLedgerPage> createState() => _SupplierLedgerPageState();
}

class _SupplierLedgerPageState extends State<SupplierLedgerPage> {
  RealtimeChannel? _channel;

  String get _businessId => context.read<AuthProvider>().businessId ?? '';
  String get _supplierName => widget.supplierName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _businessId;
      if (id.isNotEmpty) {
        context.read<SupplierProvider>().loadLedger(id, _supplierName);
        _subscribe(id);
      }
    });
  }

  void _subscribe(String businessId) {
    final client = SupabaseService.instance.client;
    _channel = client
        .channel('supplier_ledger_${businessId}_$_supplierName')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'supplier_payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: businessId,
          ),
          callback: (_) {
            if (mounted) {
              context.read<SupplierProvider>().loadLedger(businessId, _supplierName);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'supplier_payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: businessId,
          ),
          callback: (_) {
            if (mounted) {
              context.read<SupplierProvider>().loadLedger(businessId, _supplierName);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      SupabaseService.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _openRecordPayment() async {
    final id = _businessId;
    if (id.isEmpty) return;
    final provider = context.read<SupplierProvider>();
    final outstanding = provider.ledger.isEmpty
        ? 0.0
        : (provider.ledger.last.runningBalance.clamp(0, double.infinity))
            .toDouble();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordSupplierPaymentPage(
          supplierName: _supplierName,
          outstanding: outstanding,
        ),
      ),
    );
    if (!mounted) return;
    await provider.loadLedger(id, _supplierName);
    DataRefreshNotifier.instance.refresh(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SupplierProvider>();
    final ledger = provider.ledger;
    final outstanding = ledger.isEmpty
        ? 0.0
        : (ledger.last.runningBalance.clamp(0, double.infinity)).toDouble();
    final totalPurchases = ledger
        .where((e) => e.type == 'purchase')
        .fold<double>(0, (s, e) => s + e.amount);
    final totalPayments = ledger
        .where((e) => e.type == 'payment')
        .fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: Text(_supplierName)),
      floatingActionButton: outstanding > 0
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _openRecordPayment,
              icon: const Icon(MingCuteIcons.mgc_wallet_3_line),
              label: const Text('Record Payment'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _supplierName,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Supplier statement',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metric(
                      theme,
                      'Purchases',
                      CurrencyFormatter.format(totalPurchases),
                    ),
                    _metric(
                      theme,
                      'Paid',
                      CurrencyFormatter.format(totalPayments),
                    ),
                    _metric(
                      theme,
                      'Outstanding',
                      CurrencyFormatter.format(outstanding),
                      color: outstanding > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(provider.error.toString()),
            )
          else if (ledger.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No purchases or payments yet.'),
            )
          else
            Column(
              children: ledger
                  .map(
                    (e) => GreenCard(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: e.type == 'payment'
                                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                : theme.colorScheme.secondary.withValues(alpha: 0.12),
                            child: Icon(
                              e.type == 'payment'
                                  ? MingCuteIcons.mgc_arrow_down_line
                                  : MingCuteIcons.mgc_arrow_up_line,
                              color: e.type == 'payment'
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.description,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.toDDMMYYYY(
                                    DateTime.tryParse(e.date) ?? DateTime(2000),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(e.amount),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bal: ${CurrencyFormatter.format(e.runningBalance.clamp(0, double.infinity))}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _metric(
    ThemeData theme,
    String label,
    String value, {
    Color? color,
  }) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}