import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/packing_record_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/expense_entry_sheet.dart';
import '../../widgets/sale_entry_sheet.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/status_timeline.dart';
import 'batch_pl_page.dart';

class BatchDetailPage extends StatefulWidget {
  final String batchId;

  const BatchDetailPage({super.key, required this.batchId});

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> with SingleTickerProviderStateMixin {
  static const _statusFlow = [
    'purchased',
    'packed',
    'in_transit',
    'delivered',
    'selling',
    'closed',
  ];

  late final TabController _tabCtrl;

  String get batchId => widget.batchId;

  RealtimeChannel? _expensesChannel;
  RealtimeChannel? _salesChannel;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    final detail = context.read<BatchDetailProvider>();
    final pl = context.read<BatchPLProvider>();
    final expenses = context.read<ExpenseProvider>();
    final sales = context.read<SaleProvider>();
    detail.load(batchId);
    pl.load(batchId);
    expenses.load(batchId);
    sales.loadByBatch(batchId);
    _subscribeRealtime(detail, pl, expenses, sales);
  }

  void _subscribeRealtime(
    BatchDetailProvider detail,
    BatchPLProvider pl,
    ExpenseProvider expenses,
    SaleProvider sales,
  ) {
    final client = SupabaseService.instance.client;
    _expensesChannel = client
        .channel('expenses_batch_$batchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            expenses.load(batchId);
            pl.load(batchId);
            detail.load(batchId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            expenses.load(batchId);
            pl.load(batchId);
          },
        )
        .subscribe();
    _salesChannel = client
        .channel('sales_batch_$batchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sales',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            sales.loadByBatch(batchId);
            pl.load(batchId);
            detail.load(batchId);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final client = SupabaseService.instance.client;
    if (_expensesChannel != null) client.removeChannel(_expensesChannel!);
    if (_salesChannel != null) client.removeChannel(_salesChannel!);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchProvider = context.watch<BatchDetailProvider>();
    final batch = batchProvider.batch;
    final userRole = context.watch<AuthProvider>().user?.role ?? '';
    final canEdit = userRole.canEditBatch;
    final canDelete = userRole.canCloseBatch;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details'),
        actions: [
          IconButton(
            tooltip: 'Open P&L report',
            icon: const Icon(MingCuteIcons.mgc_chart_bar_line),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BatchPLPage(batchId: batchId)),
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: batch?.status == 'closed' ? 'Batch closed' : 'Mark as closed',
              icon: Icon(
                batch?.status == 'closed'
                    ? MingCuteIcons.mgc_check_circle_fill
                    : MingCuteIcons.mgc_archive_line,
                color: batch?.status == 'closed' ? AppColors.primary : null,
              ),
              onPressed: batch?.status == 'closed' ? null : () => _confirmClose(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Packing'),
            Tab(text: 'Expenses'),
            Tab(text: 'Sales'),
            Tab(text: 'P&L'),
          ],
        ),
      ),
      body: _buildBody(context, theme, batchProvider),
      floatingActionButton: (canEdit && batch?.status != 'closed') ? _buildFab(context) : null,
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, BatchDetailProvider batchProvider) {
    final batch = batchProvider.batch;
    if (batch == null) {
      if (batchProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (batchProvider.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(batchProvider.error!),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.read<BatchDetailProvider>().load(batchId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: Text('No batch data'));
    }
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _overviewTab(context, theme, batch),
        _packingTab(context, batch),
        _expensesTab(context, batch),
        _salesTab(context, batch),
        _plTab(theme),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    final tabIndex = _tabCtrl.index;
    if (tabIndex == 1) {
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddPackingDialog(context),
        icon: const Icon(MingCuteIcons.mgc_add_line),
        label: const Text('Packing'),
      );
    }
    if (tabIndex == 2) {
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          await showExpenseEntrySheet(context, batchId: batchId);
          if (!context.mounted) return;
          context.read<ExpenseProvider>().load(batchId);
          context.read<BatchPLProvider>().load(batchId);
          context.read<BatchDetailProvider>().load(batchId);
        },
        icon: const Icon(MingCuteIcons.mgc_add_line),
        label: const Text('Expense'),
      );
    }
    if (tabIndex == 3) {
      final batch = context.read<BatchDetailProvider>().batch;
      if (batch == null) return const SizedBox.shrink();
      final soldQuantity = context.read<SaleProvider>().sales.fold<double>(
            0,
            (acc, s) => acc + s.quantitySold,
          );
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          await showSaleEntrySheet(context, batch: batch, soldQuantity: soldQuantity);
          if (!context.mounted) return;
          context.read<SaleProvider>().loadByBatch(batchId);
          context.read<BatchPLProvider>().load(batchId);
          context.read<BatchDetailProvider>().load(batchId);
        },
        icon: const Icon(MingCuteIcons.mgc_add_line),
        label: const Text('Sale'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _overviewTab(BuildContext context, ThemeData theme, BatchModel batch) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch.status == 'closed')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(MingCuteIcons.mgc_lock_line, size: 16, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Closed — read only. Edits, packing, expenses and sales are locked.',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(batch.productName ?? 'Batch', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(batch.batchCode, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  StatusPill(status: batch.status),
                ],
              ),
              const SizedBox(height: 18),
              StatusTimeline(currentStatus: batch.status),
              const SizedBox(height: 18),
              _buildQuantityProgress(context, batch),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric(theme, 'Purchase Cost', CurrencyFormatter.format(batch.totalPurchaseCost)),
                  _metric(theme, 'Price / Unit', CurrencyFormatter.format(batch.purchasePricePerUnit)),
                  _metric(theme, 'Transport', batch.transportPaidBy ?? '-'),
                ],
              ),
              const SizedBox(height: 18),
              if (batch.status != 'closed')
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _advanceStatus(context, batch.status),
                    icon: const Icon(MingCuteIcons.mgc_route_line),
                    label: const Text('Advance Status'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _packingTab(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final records = detailProvider.packingRecords;
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No packing records yet. Tap + to add one.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final totalUnits = records.fold<int>(0, (acc, r) => acc + r.unitCount);
    final totalCost = records.fold<double>(0, (acc, r) => acc + r.totalPackingCost);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: _metric(theme, 'Units', totalUnits.toStringAsFixed(0))),
              Expanded(child: _metric(theme, 'Packing Cost', CurrencyFormatter.format(totalCost))),
            ],
          ),
        ),
        ...records.map((r) => _packingTile(context, r)),
      ],
    );
  }

  Widget _packingTile(BuildContext context, PackingRecordModel record) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(MingCuteIcons.mgc_box_3_line, color: theme.colorScheme.primary, size: 18),
      ),
      title: Text(
        record.unitLabel != null && record.unitLabel!.isNotEmpty
            ? record.unitLabel!
            : record.unitType,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${record.unitCount} × ${record.unitType} @ ${CurrencyFormatter.format(record.costPerUnit)}',
      ),
      trailing: Text(
        CurrencyFormatter.format(record.totalPackingCost),
        style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'Roboto Mono'),
      ),
    );
  }

  Widget _expensesTab(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final expenseProvider = context.watch<ExpenseProvider>();
    if (expenseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (expenseProvider.error != null) {
      return Center(child: Text(expenseProvider.error!));
    }
    final expenses = expenseProvider.expenses;
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No expenses yet. Tap + to add one.', style: theme.textTheme.bodyMedium),
        ),
      );
    }
    final activeExpenses = expenses.where((e) => !e.isVoided).toList();
    final voidedExpenses = expenses.where((e) => e.isVoided).toList();
    final grouped = <String, List<dynamic>>{};
    for (final e in activeExpenses) {
      grouped.putIfAbsent(e.expenseSide, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        ...grouped.entries.map((entry) {
          final sideLabel = entry.key.toUpperCase();
          final sideTotal = entry.value.fold<double>(0, (acc, e) => acc + e.amount);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    Text(sideLabel, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(CurrencyFormatter.format(sideTotal), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              ...entry.value.map((e) => _expenseTile(context, e)),
            ],
          );
        }),
        if (voidedExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('VOIDED (excluded from totals)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error)),
          ),
          ...voidedExpenses.map((e) => _expenseTile(context, e)),
        ],
      ],
    );
  }

  Widget _expenseTile(BuildContext context, ExpenseModel expense) {
    final theme = Theme.of(context);
    final isVoided = expense.isVoided;
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: isVoided
          ? Icon(MingCuteIcons.mgc_forbid_circle_line, color: theme.colorScheme.error, size: 22)
          : null,
      title: Text(
        expense.expenseType,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isVoided ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : null,
          decoration: isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          expense.description,
          expense.expenseDate,
          expense.paymentMode,
          if (isVoided && expense.voidedReason != null && expense.voidedReason!.isNotEmpty)
            'Voided: ${expense.voidedReason}',
        ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
        style: TextStyle(
          color: isVoided ? theme.colorScheme.error.withValues(alpha: 0.7) : null,
        ),
      ),
      trailing: Text(
        CurrencyFormatter.format(expense.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'Roboto Mono',
          color: isVoided ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : null,
          decoration: isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
    );

    if (isVoided) return tile;

    final canVoid = (context.read<AuthProvider>().user?.role ?? '').canVoidExpense;
    if (!canVoid) return tile;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(MingCuteIcons.mgc_forbid_circle_line, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        final reasonCtrl = TextEditingController();
        final expenseProvider = context.read<ExpenseProvider>();
        final batchPLProvider = context.read<BatchPLProvider>();
        final batchDetailProvider = context.read<BatchDetailProvider>();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Void expense?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Voided expenses are kept for audit and excluded from totals. This cannot be undone.'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim().isNotEmpty),
                child: const Text('Void'),
              ),
            ],
          ),
        );
        if (ok != true) return false;
        // Re-prompt if empty reason
        if (reasonCtrl.text.trim().isEmpty) {
          if (!context.mounted) return false;
          final reason2 = TextEditingController();
          final ok2 = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reason required'),
              content: TextField(controller: reason2, autofocus: true, decoration: const InputDecoration(labelText: 'Reason')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
              ],
            ),
          );
          if (ok2 != true || reason2.text.trim().isEmpty) return false;
          reasonCtrl.text = reason2.text;
        }
        try {
          await expenseProvider.voidExpense(expense.id, reasonCtrl.text.trim());
          expenseProvider.load(batchId);
          batchPLProvider.load(batchId);
          batchDetailProvider.load(batchId);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
          }
          return false;
        }
      },
      child: tile,
    );
  }

  Widget _salesTab(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final saleProvider = context.watch<SaleProvider>();
    if (saleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (saleProvider.error != null) {
      return Center(child: Text(saleProvider.error!));
    }
    final sales = saleProvider.sales;
    if (sales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No sales yet. Tap + to record a sale.', style: theme.textTheme.bodyMedium),
        ),
      );
    }
    final totalQty = sales.fold<double>(0, (acc, s) => acc + s.quantitySold);
    final totalRev = sales.fold<double>(0, (acc, s) => acc + s.totalAmount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: _metric(theme, 'Sold', '${totalQty.toStringAsFixed(0)} ${batch.unit}')),
              Expanded(child: _metric(theme, 'Revenue', CurrencyFormatter.format(totalRev))),
            ],
          ),
        ),
        ...sales.map((s) => _saleTile(context, s)),
      ],
    );
  }

  Widget _saleTile(BuildContext context, SaleModel sale) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _paymentColor(theme, sale.paymentMode).withValues(alpha: 0.15),
        child: Icon(_paymentIcon(sale.paymentMode), color: _paymentColor(theme, sale.paymentMode), size: 18),
      ),
      title: Text('${sale.quantitySold.toStringAsFixed(0)} @ ${CurrencyFormatter.format(sale.pricePerUnit)}'),
      subtitle: Text('${sale.saleDate} • ${sale.paymentMode}'),
      trailing: Text(
        CurrencyFormatter.format(sale.totalAmount),
        style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'Roboto Mono'),
      ),
    );
  }

  Widget _plTab(ThemeData theme) {
    final plProvider = context.watch<BatchPLProvider>();
    if (plProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (plProvider.error != null) {
      return Center(child: Text(plProvider.error!));
    }
    final pl = plProvider.pl;
    if (pl == null) {
      return const Center(child: Text('No P&L data yet'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net P&L', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(pl.netProfitLoss),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: pl.netProfitLoss >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeader(theme, 'Cost Breakdown'),
        _costLine(theme, 'Purchase Cost', pl.costBreakdown.purchaseCost),
        _costLine(theme, 'Purchaser Daily Charges', pl.costBreakdown.purchaserDailyCharges),
        _costLine(theme, 'Purchaser Expenses', pl.costBreakdown.purchaserExpenses),
        _costLine(theme, 'Packing Cost', pl.costBreakdown.packingCost),
        _costLine(theme, 'Transport', pl.costBreakdown.transportCost),
        _costLine(theme, 'Seller Daily Charges', pl.costBreakdown.sellerDailyCharges),
        _costLine(theme, 'Seller Expenses', pl.costBreakdown.sellerExpenses),
        const Divider(),
        _costLine(theme, 'TOTAL COST', pl.costBreakdown.totalCost, bold: true),
        const SizedBox(height: 16),
        _sectionHeader(theme, 'Revenue'),
        _costLine(theme, 'Total Revenue', pl.revenue.totalRevenue),
        _costLine(theme, 'Cash Received', pl.revenue.cashReceived),
        _costLine(theme, 'Credit Outstanding', pl.revenue.creditOutstanding),
      ],
    );
  }

  Widget _sectionHeader(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: theme.textTheme.titleLarge),
      );

  Widget _costLine(ThemeData theme, String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
              fontFamily: 'Roboto Mono',
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _advanceStatus(BuildContext context, String currentStatus) async {
    final index = _statusFlow.indexOf(currentStatus);
    if (index < 0 || index == _statusFlow.length - 1) return;

    final nextStatus = _statusFlow[index + 1];
    try {
      await context.read<BatchDetailProvider>().updateStatus(nextStatus);
      if (!context.mounted) return;
      context.read<BatchPLProvider>().load(batchId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch moved to $nextStatus')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Mark batch as closed?',
      message: 'Closing a batch is permanent — it locks all edits, sales, packing, and expenses for this batch. Use this when the batch is fully settled.',
      confirmLabel: 'Mark as closed',
      isDestructive: true,
    );
    if (!confirm) return;
    if (!context.mounted) return;
    final provider = context.read<BatchDetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus('closed');
      messenger.showSnackBar(
        const SnackBar(content: Text('Batch marked as closed')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _showAddPackingDialog(BuildContext context) async {
    final unitTypeCtrl = TextEditingController(text: 'bag');
    final countCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String unitType = 'bag';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Add Packing Record'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: unitType,
                    decoration: const InputDecoration(labelText: 'Unit type'),
                    items: const [
                      DropdownMenuItem(value: 'bag', child: Text('Bag')),
                      DropdownMenuItem(value: 'packet', child: Text('Packet')),
                      DropdownMenuItem(value: 'crate', child: Text('Crate')),
                      DropdownMenuItem(value: 'box', child: Text('Box')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (v) => setSt(() {
                      unitType = v ?? 'bag';
                      unitTypeCtrl.text = unitType;
                    }),
                  ),
                  TextField(controller: unitTypeCtrl, decoration: const InputDecoration(labelText: 'Unit label (optional)')),
                  TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Count')),
                  TextField(controller: costCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cost per unit')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final count = int.tryParse(countCtrl.text.trim()) ?? 0;
                  final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
                  if (count <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Count must be > 0')));
                    return;
                  }
                  try {
                    await context.read<BatchDetailProvider>().addPacking(
                          PackingRecordCreate(
                            unitType: unitType,
                            unitLabel: unitTypeCtrl.text.trim().isEmpty ? null : unitTypeCtrl.text.trim(),
                            unitCount: count,
                            costPerUnit: cost,
                          ),
                        );
                    if (!context.mounted) return;
                    context.read<BatchPLProvider>().load(batchId);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildQuantityProgress(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final sold = context.watch<SaleProvider>().sales.fold<double>(
          0,
          (acc, s) => acc + s.quantitySold,
        );
    final total = batch.totalQuantity;
    final remaining = (total - sold).clamp(0, total).toDouble();
    final pct = total > 0 ? (sold / total).clamp(0, 1).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sold vs Remaining', style: theme.textTheme.bodySmall),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: pct >= 1 ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _metric(theme, 'Sold', '${sold.toStringAsFixed(0)} ${batch.quantityUnit}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric(theme, 'Remaining', '${remaining.toStringAsFixed(0)} ${batch.quantityUnit}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              color: pct >= 1 ? AppColors.success : AppColors.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total ${total.toStringAsFixed(0)} ${batch.quantityUnit}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  IconData _paymentIcon(String mode) {
    switch (mode) {
      case 'cash': return MingCuteIcons.mgc_wallet_3_line;
      case 'credit': return MingCuteIcons.mgc_time_line;
      case 'bank_transfer': return MingCuteIcons.mgc_bank_line;
      case 'partial_credit': return MingCuteIcons.mgc_chart_pie_line;
      default: return MingCuteIcons.mgc_bill_line;
    }
  }

  Color _paymentColor(ThemeData theme, String mode) {
    switch (mode) {
      case 'cash': return theme.colorScheme.primary;
      case 'credit': return theme.colorScheme.error;
      case 'bank_transfer': return Colors.blue;
      case 'partial_credit': return theme.colorScheme.secondary;
      default: return theme.colorScheme.outline;
    }
  }
}
