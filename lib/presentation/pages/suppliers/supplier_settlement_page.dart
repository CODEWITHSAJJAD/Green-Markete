import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'supplier_ledger_page.dart';

class SupplierSettlementPage extends StatefulWidget {
  const SupplierSettlementPage({super.key});

  @override
  State<SupplierSettlementPage> createState() => _SupplierSettlementPageState();
}

class _SupplierSettlementPageState extends State<SupplierSettlementPage> {
  RealtimeChannel? _paymentsChannel;

  String get _businessId => context.read<AuthProvider>().businessId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _businessId;
      if (id.isNotEmpty) {
        context.read<SupplierProvider>().loadOutstanding(id);
        _subscribe(id);
      }
    });
  }

  void _subscribe(String businessId) {
    final client = SupabaseService.instance.client;
    _paymentsChannel = client
        .channel('supplier_payments_$businessId')
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
              context.read<SupplierProvider>().loadOutstanding(businessId);
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
              context.read<SupplierProvider>().loadOutstanding(businessId);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_paymentsChannel != null) {
      SupabaseService.instance.client.removeChannel(_paymentsChannel!);
    }
    super.dispose();
  }

  Future<void> _openLedger(SupplierOutstanding s) async {
    final id = _businessId;
    if (id.isEmpty) return;
    await context
        .read<SupplierProvider>()
        .loadLedger(id, s.supplierName);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierLedgerPage(supplierName: s.supplierName),
      ),
    );
    if (!mounted) return;
    context.read<SupplierProvider>().loadOutstanding(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SupplierProvider>();
    final outstanding = provider.outstanding;
    final totalOutstanding = outstanding.fold<double>(
      0,
      (s, o) => s + o.outstanding,
    );
    final totalDue = outstanding.fold<double>(0, (s, o) => s + o.totalDue);
    final totalPaid =
        outstanding.fold<double>(0, (s, o) => s + o.totalPaid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Settlements'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final id = _businessId;
          if (id.isNotEmpty) {
            await context.read<SupplierProvider>().loadOutstanding(id);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.10),
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
                    'Supplier payables',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track what you owe each supplier from multi-supplier batch purchases and record payments — same workflow as customer credit.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric(theme, 'Total due', CurrencyFormatter.format(totalDue)),
                      _metric(theme, 'Total paid', CurrencyFormatter.format(totalPaid)),
                      _metric(
                        theme,
                        'Outstanding',
                        CurrencyFormatter.format(totalOutstanding),
                        color: totalOutstanding > 0
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
                child: Column(
                  children: [
                    Text(provider.error.toString()),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context
                          .read<SupplierProvider>()
                          .loadOutstanding(_businessId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (outstanding.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: MingCuteIcons.mgc_store_2_line,
                  title: 'No suppliers yet',
                  subtitle: 'Add multi-supplier purchases in the batch wizard and they will appear here for settlement.',
                ),
              )
            else
              Column(
                children: outstanding
                    .map(
                      (s) => GreenCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        onTap: () => _openLedger(s),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: s.outstanding > 0
                                  ? AppColors.error.withValues(alpha: 0.12)
                                  : AppColors.success.withValues(alpha: 0.12),
                              child: Icon(
                                s.outstanding > 0
                                    ? MingCuteIcons.mgc_time_line
                                    : MingCuteIcons.mgc_check_circle_fill,
                                color: s.outstanding > 0
                                    ? AppColors.error
                                    : AppColors.success,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.supplierName,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Due ${CurrencyFormatter.format(s.totalDue)} · Paid ${CurrencyFormatter.format(s.totalPaid)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(s.outstanding),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: s.outstanding > 0
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.outstanding > 0 ? 'Outstanding' : 'Settled',
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
      width: 165,
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