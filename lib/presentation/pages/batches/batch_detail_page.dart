import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/batch_vehicle_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/packing_record_model.dart';
import '../../../data/models/packing_return_model.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../providers/data_refresh.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/expense_entry_sheet.dart';
import '../../widgets/sale_entry_sheet.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/status_timeline.dart';
import 'batch_pl_page.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class BatchDetailPage extends StatefulWidget {
  final String batchId;

  const BatchDetailPage({super.key, required this.batchId});

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage>
    with SingleTickerProviderStateMixin {
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
    _tabCtrl = TabController(length: 8, vsync: this);
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
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<PartnerProvider>().load(businessId);
    }
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
              tooltip: batch?.status == 'closed'
                  ? 'Batch closed'
                  : 'Mark as closed',
              icon: Icon(
                batch?.status == 'closed'
                    ? MingCuteIcons.mgc_check_circle_fill
                    : MingCuteIcons.mgc_archive_line,
                color: batch?.status == 'closed' ? AppColors.primary : null,
              ),
              onPressed: batch?.status == 'closed'
                  ? null
                  : () => _confirmClose(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Packing'),
            Tab(text: 'Returns'),
            Tab(text: 'Expenses'),
            Tab(text: 'Transport'),
            Tab(text: 'Sales'),
            Tab(text: 'Settlements'),
            Tab(text: 'P&L'),
          ],
        ),
      ),
      body: _buildBody(context, theme, batchProvider),
      floatingActionButton: (canEdit && batch?.status != 'closed')
          ? _buildFab(context)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    BatchDetailProvider batchProvider,
  ) {
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
                  onPressed: () =>
                      context.read<BatchDetailProvider>().load(batchId),
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
        _returnsTab(context, batch),
        _expensesTab(context, batch),
        _transportTab(context, batch),
        _salesTab(context, batch),
        _settlementsTab(context, batch),
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
        onPressed: () => _showAddReturnDialog(context),
        icon: const Icon(MingCuteIcons.mgc_arrow_to_left_line),
        label: const Text('Return'),
      );
    }
    if (tabIndex == 3) {
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
    if (tabIndex == 4) {
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddTransportDialog(context),
        icon: const Icon(MingCuteIcons.mgc_truck_line),
        label: const Text('Load'),
      );
    }
    if (tabIndex == 5) {
      final batch = context.read<BatchDetailProvider>().batch;
      if (batch == null) return const SizedBox.shrink();
      final soldQuantity = context.read<SaleProvider>().sales.fold<double>(
        0,
        (acc, s) => acc + s.quantitySold,
      );
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          final saved = await showSaleEntrySheet(
            context,
            batch: batch,
            soldQuantity: soldQuantity,
          );
          if (!context.mounted) return;
          context.read<SaleProvider>().loadByBatch(batchId);
          context.read<BatchPLProvider>().load(batchId);
          context.read<BatchDetailProvider>().load(batchId);
          if (saved == true) {
            final businessId = context.read<AuthProvider>().businessId;
            if (businessId != null && businessId.isNotEmpty) {
              DataRefreshNotifier.instance.refresh(businessId);
            }
          }
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
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch.status == 'closed')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        MingCuteIcons.mgc_lock_line,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
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
                        Text(
                          batch.productName ?? 'Batch',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          batch.batchCode,
                          style: theme.textTheme.bodyMedium,
                        ),
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
                  _metric(
                    theme,
                    'Purchase Cost',
                    CurrencyFormatter.format(batch.totalPurchaseCost),
                  ),
                  _metric(
                    theme,
                    'Price / Unit',
                    CurrencyFormatter.format(batch.purchasePricePerUnit),
                  ),
                  _metric(theme, 'Transport', batch.transportPaidBy ?? '-'),
                ],
              ),
              if (batch.supplierName != null &&
                  batch.supplierName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(MingCuteIcons.mgc_store_line, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Supplier: ${batch.supplierName}',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (batch.purchasePaymentMode != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(MingCuteIcons.mgc_wallet_3_line, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _purchasePaymentSummary(batch),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
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
    final totalCost = records.fold<double>(
      0,
      (acc, r) => acc + r.totalPackingCost,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _metric(theme, 'Units', totalUnits.toStringAsFixed(0)),
              ),
              Expanded(
                child: _metric(
                  theme,
                  'Packing Cost',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
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
        child: Icon(
          MingCuteIcons.mgc_box_3_line,
          color: theme.colorScheme.primary,
          size: 18,
        ),
      ),
      title: Text(
        record.unitLabel != null && record.unitLabel!.isNotEmpty
            ? record.unitLabel!
            : record.unitType,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${record.unitCount} × ${record.unitType} — ${CurrencyFormatter.format(record.costPerUnit)}/unit',
      ),
      trailing: Text(
        CurrencyFormatter.format(record.totalPackingCost),
        style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'Roboto Mono'),
      ),
    );
  }

  Widget _returnsTab(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final returns = detailProvider.returns;
    if (returns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No returns yet. Tap + to record goods returned by a buyer.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final totalQty = returns.fold<double>(0, (acc, r) => acc + r.quantity);
    final totalCost = returns.fold<double>(
      0,
      (acc, r) => acc + r.totalReturnCost,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _metric(
                  theme,
                  'Returned',
                  '${totalQty.toStringAsFixed(0)} ${batch.unit}',
                ),
              ),
              Expanded(
                child: _metric(
                  theme,
                  'Return Value',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        ...returns.map((r) => _returnTile(context, r)),
      ],
    );
  }

  Widget _returnTile(BuildContext context, PackingReturnModel item) {
    final theme = Theme.of(context);
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.12),
        child: Icon(
          MingCuteIcons.mgc_arrow_to_left_line,
          color: theme.colorScheme.error,
          size: 18,
        ),
      ),
      title: Text(
        '${item.quantity.toStringAsFixed(0)} ${item.unitType ?? 'units'} returned',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        [
          item.packingLabel,
          item.returnDate,
          item.notes,
        ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
      ),
      trailing: item.totalReturnCost > 0
          ? Text(
              CurrencyFormatter.format(item.totalReturnCost),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Roboto Mono',
              ),
            )
          : null,
    );
    final canDelete =
        (context.read<AuthProvider>().user?.role ?? '').canEditBatch;
    if (!canDelete) return tile;
    return Dismissible(
      key: ValueKey('return-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          MingCuteIcons.mgc_delete_2_line,
          color: theme.colorScheme.error,
        ),
      ),
      confirmDismiss: (_) async {
        final batchDetailProvider = context.read<BatchDetailProvider>();
        final ok = await showConfirmDialog(
          context,
          title: 'Remove this return?',
          message:
              'The return of ${item.quantity.toStringAsFixed(0)} units will be removed from this batch.',
          confirmLabel: 'Remove',
          isDestructive: true,
        );
        if (ok != true) return false;
        try {
          await batchDetailProvider.deleteReturn(item.id);
          if (!context.mounted) return false;
          context.read<BatchPLProvider>().load(batchId);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
              ),
            );
          }
          return false;
        }
      },
      child: tile,
    );
  }

  Future<void> _showAddReturnDialog(BuildContext context) async {
    final detailProvider = context.read<BatchDetailProvider>();
    final packing = detailProvider.packingRecords;
    final theme = Theme.of(context);
    if (packing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a packing record first')),
      );
      return;
    }
    String? packingIndex;
    final quantityCtrl = TextEditingController();
    final countCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Record Return'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField2<String>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(packingIndex),
                  decoration: const InputDecoration(
                    labelText: 'Packing record',
                  ),
                  items: [
                    for (var i = 0; i < packing.length; i++)
                      DropdownItem(
                        value: '$i',
                        child: Text(
                          '${i + 1}. ${packing[i].unitLabel ?? packing[i].unitType} × ${packing[i].unitCount}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => packingIndex = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantity returned',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Count (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Return value is estimated from the linked packing record\u2019s cost per unit.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final idx = int.tryParse(packingIndex ?? '') ?? -1;
                if (idx < 0 || idx >= packing.length) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Select a packing record')),
                  );
                  return;
                }
                final quantity = double.tryParse(quantityCtrl.text.trim()) ?? 0;
                if (quantity <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Quantity must be > 0')),
                  );
                  return;
                }
                try {
                  await detailProvider.addReturn(
                    PackingReturnCreate(
                      packingRecordId: packing[idx].id,
                      quantity: quantity,
                      count: int.tryParse(countCtrl.text.trim()),
                      returnDate: DateTime.now()
                          .toIso8601String()
                          .split('T')
                          .first,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    ),
                  );
                  if (!ctx.mounted) return;
                  context.read<BatchPLProvider>().load(batchId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
          child: Text(
            'No expenses yet. Tap + to add one.',
            style: theme.textTheme.bodyMedium,
          ),
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
          final sideTotal = entry.value.fold<double>(
            0,
            (acc, e) => acc + e.amount,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(sideLabel, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(sideTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
            child: Text(
              'VOIDED (excluded from totals)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
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
          ? Icon(
              MingCuteIcons.mgc_forbid_circle_line,
              color: theme.colorScheme.error,
              size: 22,
            )
          : null,
      title: Text(
        expense.expenseType,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isVoided
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
          decoration: isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          expense.description,
          expense.expenseDate,
          expense.paymentMode,
          if (isVoided &&
              expense.voidedReason != null &&
              expense.voidedReason!.isNotEmpty)
            'Voided: ${expense.voidedReason}',
        ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
        style: TextStyle(
          color: isVoided
              ? theme.colorScheme.error.withValues(alpha: 0.7)
              : null,
        ),
      ),
      trailing: Text(
        CurrencyFormatter.format(expense.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'Roboto Mono',
          color: isVoided
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
          decoration: isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
    );

    if (isVoided) return tile;

    final canVoid =
        (context.read<AuthProvider>().user?.role ?? '').canVoidExpense;
    if (!canVoid) return tile;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          MingCuteIcons.mgc_forbid_circle_line,
          color: theme.colorScheme.error,
        ),
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
                const Text(
                  'Voided expenses are kept for audit and excluded from totals. This cannot be undone.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () =>
                    Navigator.pop(ctx, reasonCtrl.text.trim().isNotEmpty),
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
              content: TextField(
                controller: reason2,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit'),
                ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
              ),
            );
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
          child: Text(
            'No sales yet. Tap + to record a sale.',
            style: theme.textTheme.bodyMedium,
          ),
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _metric(
                  theme,
                  'Sold',
                  '${totalQty.toStringAsFixed(0)} ${batch.unit}',
                ),
              ),
              Expanded(
                child: _metric(
                  theme,
                  'Revenue',
                  CurrencyFormatter.format(totalRev),
                ),
              ),
            ],
          ),
        ),
        ...sales.map((s) => _saleTile(context, s, batch.unit)),
      ],
    );
  }

  Widget _saleTile(BuildContext context, SaleModel sale, String unit) {
    final theme = Theme.of(context);
    final walkInCredit = sale.customerId == null && sale.creditAmount > 0;
    final canCollect =
        walkInCredit &&
        (context.read<AuthProvider>().user?.role ?? '').canEditBatch;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _paymentColor(
          theme,
          sale.paymentMode,
        ).withValues(alpha: 0.15),
        child: Icon(
          _paymentIcon(sale.paymentMode),
          color: _paymentColor(theme, sale.paymentMode),
          size: 18,
        ),
      ),
      title: Text(
        '${sale.quantitySold.toStringAsFixed(0)} $unit × ${CurrencyFormatter.format(sale.pricePerUnit)}',
      ),
      subtitle: Text(
        [
          '${sale.saleDate} • ${sale.paymentMode}',
          if (walkInCredit)
            'Walk-in credit left: ${CurrencyFormatter.format(sale.creditAmount)}',
        ].join('\n'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.format(sale.totalAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Roboto Mono',
            ),
          ),
          if (canCollect) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Collect walk-in credit',
              visualDensity: VisualDensity.compact,
              onPressed: () => _collectWalkInCreditDialog(context, sale),
              icon: const Icon(MingCuteIcons.mgc_cash_line, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _collectWalkInCreditDialog(
    BuildContext context,
    SaleModel sale,
  ) async {
    final theme = Theme.of(context);
    final businessId = context.read<AuthProvider>().businessId ?? '';
    final remaining = sale.creditAmount;
    final amountCtrl = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
    );
    final bankRefCtrl = TextEditingController();
    String paymentMode = 'cash';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Collect Walk-in Credit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Outstanding credit: ${CurrencyFormatter.format(remaining)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(paymentMode),
                    decoration: const InputDecoration(
                      labelText: 'Payment mode',
                    ),
                    items: const [
                      DropdownItem(value: 'cash', child: Text('Cash')),
                      DropdownItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer'),
                      ),
                    ],
                    onChanged: (v) => setSt(() => paymentMode = v ?? 'cash'),
                  ),
                  if (paymentMode == 'bank_transfer') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankRefCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bank reference',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  if (amount > remaining + 0.01) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Amount exceeds outstanding credit'),
                      ),
                    );
                    return;
                  }
                  final saleProvider = context.read<SaleProvider>();
                  final ok = await saleProvider.collectCredit(
                    sale.id,
                    amount: amount,
                    paymentMode: paymentMode,
                    bankReference: bankRefCtrl.text.trim().isEmpty
                        ? null
                        : bankRefCtrl.text.trim(),
                  );
                  if (!ctx.mounted) return;
                  if (ok) {
                    Navigator.pop(ctx);
                    context.read<BatchPLProvider>().load(sale.batchId);
                    if (businessId.isNotEmpty) {
                      DataRefreshNotifier.instance.refresh(businessId);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Credit collected')),
                    );
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed: ${saleProvider.error ?? 'Unknown error'}',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Collect'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _transportTab(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loads = detailProvider.vehicleLoads;
    if (loads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No vehicle loads yet. Tap + to assign transport to a vehicle.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Group loads by vehicle so a vehicle loaded with multiple packing types
    // shows once, with combined units and the total fare for that vehicle.
    final grouped = <String, List<BatchVehicleModel>>{};
    for (final l in loads) {
      grouped.putIfAbsent(l.vehicleId, () => []).add(l);
    }
    final packingById = {
      for (final p in detailProvider.packingRecords) p.id: p,
    };
    final totalCost = loads.fold<double>(0, (acc, l) => acc + l.totalCost);
    final transportPaidBy = batch.transportPaidBy ?? 'purchaser';
    final transportPartnerId = detailProvider.batchPartners
        .where(
          (p) =>
              p['role'] == transportPaidBy ||
              p['role'] == 'both',
        )
        .map((p) => p['partner_id'] as String?)
        .whereType<String>()
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: _metric(theme, 'Vehicles', '${grouped.length}')),
              Expanded(
                child: _metric(
                  theme,
                  'Transport Cost',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        if (transportPartnerId != null) ...[
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () => _showPayTransportDialog(
              context,
              batch: batch,
              totalCost: totalCost,
              transportPartnerId: transportPartnerId,
            ),
            icon: const Icon(MingCuteIcons.mgc_wallet_3_line),
            label: const Text('Pay Transport'),
          ),
          const SizedBox(height: 8),
        ],
        ...grouped.entries.map(
          (entry) => _vehicleGroup(context, batch, entry.value, packingById),
        ),
      ],
    );
  }

  /// One card per vehicle combining all loads (packing types) on that vehicle,
  /// with the combined units and the total fare.
  Widget _vehicleGroup(
    BuildContext context,
    BatchModel batch,
    List<BatchVehicleModel> loads,
    Map<String, PackingRecordModel> packingById,
  ) {
    final theme = Theme.of(context);
    final first = loads.first;
    final combinedUnits = loads.fold<double>(0, (acc, l) => acc + l.unitCount);
    final fare = loads.fold<double>(0, (acc, l) => acc + l.totalCost);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  MingCuteIcons.mgc_truck_line,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.vehiclePlateNumber ?? 'Vehicle',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (first.driverName != null && first.driverName!.isNotEmpty)
                      Text(first.driverName!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(fare),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                  Text('Fare', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          ...loads.map(
            (l) => _loadRow(
              context,
              batch,
              l,
              _transportLoadLabel(l, packingById),
            ),
          ),
          if (combinedUnits > 0) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loads.length > 1
                        ? '${loads.length} loads on this vehicle'
                        : 'Units loaded',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${combinedUnits.toStringAsFixed(combinedUnits % 1 == 0 ? 0 : 1)} units total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _loadRow(
    BuildContext context,
    BatchModel batch,
    BatchVehicleModel load,
    String label,
  ) {
    final theme = Theme.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (load.costType == 'per_packing' && load.unitCount > 0)
                      '${load.unitCount.toStringAsFixed(load.unitCount % 1 == 0 ? 0 : 1)} units × ${CurrencyFormatter.format(load.transportCost)}/unit'
                    else if (load.costType == 'per_packing')
                      '${CurrencyFormatter.format(load.transportCost)}/unit'
                    else if (load.costType == 'lump_sum')
                      'Lump sum'
                    else
                      'Flat fare',
                    load.loadDate,
                  ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(load.totalCost),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
    final canDelete =
        (context.read<AuthProvider>().user?.role ?? '').canEditBatch;
    if (!canDelete) return tile;
    return Dismissible(
      key: ValueKey('vehicle-load-${load.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          MingCuteIcons.mgc_delete_2_line,
          color: theme.colorScheme.error,
        ),
      ),
      confirmDismiss: (_) async {
        final batchDetailProvider = context.read<BatchDetailProvider>();
        final batchPLProvider = context.read<BatchPLProvider>();
        final ok = await showConfirmDialog(
          context,
          title: 'Remove this load?',
          message:
              'The transport load for ${load.vehiclePlateNumber ?? 'this vehicle'} will be removed from this batch.',
          confirmLabel: 'Remove',
          isDestructive: true,
        );
        if (ok != true) return false;
        try {
          await batchDetailProvider.deleteVehicleLoad(load.id);
          if (!context.mounted) return false;
          batchPLProvider.load(batch.id);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
              ),
            );
          }
          return false;
        }
      },
      child: tile,
    );
  }

  /// Resolves the packing label shown for a transport load. Loads store only a
  /// packing_record_id, so the label comes from the batch's packing records.
  String _transportLoadLabel(
    BatchVehicleModel load,
    Map<String, PackingRecordModel> packingById,
  ) {
    final id = load.packingRecordId;
    final packing = id == null ? null : packingById[id];
    if (packing != null) {
      final type = packing.unitType.toLowerCase();
      if (type.isEmpty || type.contains('custom') || type.contains('loose')) {
        final name =
            packing.unitLabel == null || packing.unitLabel!.isEmpty
                ? 'Loose'
                : packing.unitLabel!;
        return name;
      }
      return '${packing.unitType} × ${packing.unitCount}';
    }
    return load.packingLabel ?? 'Load';
  }

  Future<void> _showPayTransportDialog(
    BuildContext context, {
    required BatchModel batch,
    required double totalCost,
    required String transportPartnerId,
  }) async {
    final theme = Theme.of(context);
    final businessId = context.read<AuthProvider>().businessId ?? '';
    final side = batch.transportPaidBy ?? 'purchaser';
    final partners = context.read<PartnerProvider>().partners;

    String partnerName(String id) {
      return partners
              .where((p) => p.id == id)
              .map((p) => p.fullName)
              .firstOrNull ??
          id;
    }

    final amountCtrl = TextEditingController(
      text: totalCost > 0 ? totalCost.toStringAsFixed(2) : '',
    );
    final notesCtrl = TextEditingController(
      text: 'Transport payment for batch ${batch.batchCode}',
    );
    final refCtrl = TextEditingController();
    String paymentMode = 'cash';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Pay Transport'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'The ${side == 'seller' ? 'seller' : 'purchaser'} side pays the vehicle fares directly. This is recorded as a ${side == 'seller' ? 'seller' : 'purchaser'}-side transport expense.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Paid by: ${partnerName(transportPartnerId)} (${side == 'seller' ? 'Seller' : 'Purchaser'})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total transport fare: ${CurrencyFormatter.format(totalCost)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(paymentMode),
                    decoration: const InputDecoration(
                      labelText: 'Payment mode',
                    ),
                    items: const [
                      DropdownItem(value: 'cash', child: Text('Cash')),
                      DropdownItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer'),
                      ),
                    ],
                    onChanged: (v) => setSt(() => paymentMode = v ?? 'cash'),
                  ),
                  if (paymentMode == 'bank_transfer') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: refCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bank reference',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  final expenseProvider = context.read<ExpenseProvider>();
                  final ok = await expenseProvider.add(
                    batch.id,
                    ExpenseCreate(
                      expenseSide: side,
                      expenseType: 'transport',
                      amount: amount,
                      description: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      paidBy: transportPartnerId,
                      paymentMode: paymentMode,
                      paymentReference: refCtrl.text.trim().isEmpty
                          ? null
                          : refCtrl.text.trim(),
                      expenseDate: DateTime.now()
                          .toIso8601String()
                          .split('T')
                          .first,
                    ),
                  );
                  if (!ctx.mounted) return;
                  if (ok) {
                    context.read<BatchPLProvider>().load(batch.id);
                    if (businessId.isNotEmpty) {
                      DataRefreshNotifier.instance.refresh(businessId);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transport payment recorded'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed: ${expenseProvider.error ?? 'Unknown error'}',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Save Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddTransportDialog(BuildContext context) async {
    final vehiclesProvider = context.read<VehicleProvider>();
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null &&
        businessId.isNotEmpty &&
        vehiclesProvider.vehicles.isEmpty) {
      await vehiclesProvider.load(businessId);
    }
    if (!context.mounted) return;
    final vehicles = vehiclesProvider.vehicles;
    final packing = context.read<BatchDetailProvider>().packingRecords;
    final detailProvider = context.read<BatchDetailProvider>();
    String? vehicleId;
    int? packingIndex;
    String costType = 'per_vehicle';
    final unitCountCtrl = TextEditingController(text: '0');
    final transportCostCtrl = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Add Vehicle Load'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      valueListenable: ValueNotifier(vehicleId),
                      decoration: const InputDecoration(labelText: 'Vehicle'),
                      items: [
                        for (final v in vehicles)
                          DropdownItem(
                            value: v.id,
                            child: Text(
                              v.plateNumber,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setSt(() => vehicleId = v),
                    ),
                    if (packing.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField2<int>(
                        isExpanded: true,
                        valueListenable: ValueNotifier(packingIndex),
                        decoration: const InputDecoration(
                          labelText: 'Packing record (optional)',
                        ),
                        items: [
                          for (var i = 0; i < packing.length; i++)
                            DropdownItem(
                              value: i,
                              child: Text(
                                '${i + 1}. ${packing[i].unitLabel ?? packing[i].unitType} × ${packing[i].unitCount}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setSt(() => packingIndex = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      valueListenable: ValueNotifier(costType),
                      decoration: const InputDecoration(labelText: 'Cost type'),
                      items: const [
                        DropdownItem(
                          value: 'per_vehicle',
                          child: Text('Flat per vehicle'),
                        ),
                        DropdownItem(
                          value: 'per_packing',
                          child: Text('Per unit loaded'),
                        ),
                        DropdownItem(
                          value: 'lump_sum',
                          child: Text('Lump sum'),
                        ),
                      ],
                      onChanged: (v) =>
                          setSt(() => costType = v ?? 'per_vehicle'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitCountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Units loaded',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: transportCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: costType == 'per_packing'
                            ? 'Transport cost per unit'
                            : 'Transport cost',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (vehicleId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Select a vehicle')),
                      );
                      return;
                    }
                    try {
                      await detailProvider.addVehicleLoad(
                        VehicleLoadCreate(
                          vehicleId: vehicleId!,
                          packingRecordId: packingIndex != null
                              ? packing[packingIndex!].id
                              : null,
                          unitCount:
                              double.tryParse(unitCountCtrl.text.trim()) ?? 0,
                          costType: costType,
                          transportCost:
                              double.tryParse(transportCostCtrl.text.trim()) ??
                              0,
                          loadDate: DateTime.now()
                              .toIso8601String()
                              .split('T')
                              .first,
                        ),
                      );
                      if (!ctx.mounted) return;
                      context.read<BatchPLProvider>().load(batchId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _ledgerSellerId;

  Widget _settlementsTab(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
    final plProvider = context.watch<BatchPLProvider>();
    final detailProvider = context.watch<BatchDetailProvider>();
    final partnerProvider = context.watch<PartnerProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final pl = plProvider.pl;

    final batchPartners = detailProvider.batchPartners;
    final sellers = batchPartners
        .where((p) => p['role'] == 'seller' || p['role'] == 'both')
        .toList();
    if (sellers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No selling partner on this batch. Add a seller in the wizard to track settlements.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final sellerId = sellers.first['partner_id'] as String;
    final sellerName =
        partnerProvider.partners
            .where((p) => p.id == sellerId)
            .map((p) => p.fullName)
            .firstOrNull ??
        'Seller';

    if (_ledgerSellerId != sellerId) {
      _ledgerSellerId = sellerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<TransactionProvider>().loadLedger(sellerId);
      });
    }

    final ledgerRows = txProvider.ledger?['transactions'];
    final ledgerTxs = ledgerRows is List
        ? ledgerRows
              .whereType<Map<String, dynamic>>()
              .map(TransactionModel.fromJson)
              .toList()
        : <TransactionModel>[];
    final settledForBatch = ledgerTxs
        .where(
          (t) =>
              (t.notes?.contains(batch.batchCode) ?? false) ||
              (t.reference?.contains(batch.batchCode) ?? false),
        )
        .where((t) => t.toPartnerId == sellerId)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final purchaseCost = pl?.costBreakdown.purchaseCost ?? 0;
    final purchaserDaily = pl?.costBreakdown.purchaserDailyCharges ?? 0;
    final purchaserExpenses = pl?.costBreakdown.purchaserExpenses ?? 0;
    final packingCost = pl?.costBreakdown.packingCost ?? 0;
    final transport = pl?.costBreakdown.transportCost ?? 0;
    // The bill owed to the seller is the purchaser-side total: purchase cost,
    // purchaser expenses, purchaser daily charges, packing cost and, when the
    // purchaser bears transport, the transport cost too.
    final transportInBill = batch.transportPaidBy == 'purchaser' ? transport : 0;
    final owed =
        purchaseCost +
        purchaserDaily +
        purchaserExpenses +
        packingCost +
        transportInBill;
    final remaining = (owed - settledForBatch)
        .clamp(0, double.infinity)
        .toDouble();

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
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seller: $sellerName', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _costLine(theme, 'Purchase cost', purchaseCost),
              _costLine(theme, 'Purchaser expenses', purchaserExpenses),
              _costLine(theme, 'Purchaser daily charges', purchaserDaily),
              _costLine(theme, 'Packing cost', packingCost),
              if (batch.transportPaidBy == 'purchaser')
                _costLine(theme, 'Transport (purchaser-paid)', transport),
              const Divider(height: 20),
              _costLine(theme, 'Bill owed to seller', owed, bold: true),
              _costLine(theme, 'Settled for this batch', settledForBatch),
              _costLine(theme, 'Remaining', remaining, bold: true),
              if (remaining > 0) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _settleSellerDialog(
                    context,
                    batch: batch,
                    sellerId: sellerId,
                    sellerName: sellerName,
                    remaining: remaining,
                    settledForBatch: settledForBatch,
                  ),
                  icon: const Icon(MingCuteIcons.mgc_wallet_3_line),
                  label: const Text('Settle Seller'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The bill owed to the seller is the purchaser-side total (purchase cost + purchaser expenses + daily charges + packing + purchaser-paid transport). Settle it fully or in partial splits — each payment is recorded as a partner transaction and matched to this batch via its code in the notes.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _settleSellerDialog(
    BuildContext context, {
    required BatchModel batch,
    required String sellerId,
    required String sellerName,
    required double remaining,
    required double settledForBatch,
  }) async {
    final theme = Theme.of(context);
    final businessId = context.read<AuthProvider>().businessId ?? '';
    final batchPartners = context.read<BatchDetailProvider>().batchPartners;
    final partners = context.read<PartnerProvider>().partners;
    final purchasers = batchPartners
        .where((p) => p['role'] == 'purchaser' || p['role'] == 'both')
        .map((p) => p['partner_id'] as String?)
        .whereType<String>()
        .toList();
    String? fromPartnerId = purchasers.isNotEmpty ? purchasers.first : null;
    final amountCtrl = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
    );
    final notesCtrl = TextEditingController(
      text: 'Settlement for batch ${batch.batchCode}',
    );
    String paymentMode = 'cash';

    String partnerName(String id) {
      return partners
              .where((p) => p.id == id)
              .map((p) => p.fullName)
              .firstOrNull ??
          id;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text('Settle $sellerName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(fromPartnerId),
                    decoration: const InputDecoration(
                      labelText: 'Paid by (partner)',
                    ),
                    items: [
                      for (final p in purchasers)
                        DropdownItem(
                          value: p,
                          child: Text(
                            partnerName(p),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setSt(() => fromPartnerId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      helperText: 'Enter a partial amount to pay in splits',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(paymentMode),
                    decoration: const InputDecoration(
                      labelText: 'Payment mode',
                    ),
                    items: const [
                      DropdownItem(value: 'cash', child: Text('Cash')),
                      DropdownItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer'),
                      ),
                    ],
                    onChanged: (v) => setSt(() => paymentMode = v ?? 'cash'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Owed: ${CurrencyFormatter.format(remaining)} Â· Settled: ${CurrencyFormatter.format(settledForBatch)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')),
                    );
                    return;
                  }
                  if (fromPartnerId == null || fromPartnerId!.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Select who is paying')),
                    );
                    return;
                  }
                  final txProvider = context.read<TransactionProvider>();
                  try {
                    final created = await txProvider.create(
                      TransactionCreateRequest(
                        businessId: businessId,
                        fromPartnerId: fromPartnerId!,
                        toPartnerId: sellerId,
                        amount: amount,
                        transactionType: 'settlement',
                        paymentMode: paymentMode,
                        transactionDate: DateTime.now()
                            .toIso8601String()
                            .split('T')
                            .first,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      ),
                    );
                    if (created != null) {
                      txProvider.loadLedger(sellerId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } else if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed: ${txProvider.error ?? 'Unknown error'}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save Settlement'),
              ),
            ],
          );
        },
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
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net P&L', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(pl.netProfitLoss),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: pl.netProfitLoss >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeader(theme, 'Cost Breakdown'),
        _costLine(theme, 'Purchase Cost', pl.costBreakdown.purchaseCost),
        _costLine(
          theme,
          'Purchaser Daily Charges',
          pl.costBreakdown.purchaserDailyCharges,
        ),
        _costLine(
          theme,
          'Purchaser Expenses',
          pl.costBreakdown.purchaserExpenses,
        ),
        _costLine(theme, 'Packing Cost', pl.costBreakdown.packingCost),
        _costLine(theme, 'Transport', pl.costBreakdown.transportCost),
        _costLine(
          theme,
          'Seller Daily Charges',
          pl.costBreakdown.sellerDailyCharges,
        ),
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

  Widget _costLine(
    ThemeData theme,
    String title,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
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

  Future<void> _advanceStatus(
    BuildContext context,
    String currentStatus,
  ) async {
    final index = _statusFlow.indexOf(currentStatus);
    if (index < 0 || index == _statusFlow.length - 1) return;

    final nextStatus = _statusFlow[index + 1];
    try {
      await context.read<BatchDetailProvider>().updateStatus(nextStatus);
      if (!context.mounted) return;
      context.read<BatchPLProvider>().load(batchId);
      final businessId = context.read<AuthProvider>().businessId;
      if (businessId != null && businessId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(businessId);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Batch moved to $nextStatus')));
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
      message:
          'Closing a batch is permanent — it locks all edits, sales, packing, and expenses for this batch. Use this when the batch is fully settled.',
      confirmLabel: 'Mark as closed',
      isDestructive: true,
    );
    if (!confirm) return;
    if (!context.mounted) return;
    final provider = context.read<BatchDetailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final businessId = context.read<AuthProvider>().businessId;
    try {
      await provider.updateStatus('closed');
      if (businessId != null && businessId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(businessId);
      }
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
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Add Packing Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      valueListenable: ValueNotifier(unitType),
                      decoration: const InputDecoration(labelText: 'Unit type'),
                      items: const [
                        DropdownItem(value: 'bag', child: Text('Bag')),
                        DropdownItem(value: 'packet', child: Text('Packet')),
                        DropdownItem(value: 'crate', child: Text('Crate')),
                        DropdownItem(value: 'box', child: Text('Box')),
                        DropdownItem(value: 'custom', child: Text('Custom')),
                      ],
                      onChanged: (v) => setSt(() {
                        unitType = v ?? 'bag';
                        unitTypeCtrl.text = unitType;
                      }),
                    ),
                    TextField(
                      controller: unitTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unit label (optional)',
                      ),
                    ),
                    TextField(
                      controller: countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Count'),
                    ),
                    TextField(
                      controller: costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cost per unit',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final count = int.tryParse(countCtrl.text.trim()) ?? 0;
                    final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
                    if (count <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Count must be > 0')),
                      );
                      return;
                    }
                    try {
                      await context.read<BatchDetailProvider>().addPacking(
                        PackingRecordCreate(
                          unitType: unitType,
                          unitLabel: unitTypeCtrl.text.trim().isEmpty
                              ? null
                              : unitTypeCtrl.text.trim(),
                          unitCount: count,
                          costPerUnit: cost,
                        ),
                      );
                      if (!context.mounted) return;
                      context.read<BatchPLProvider>().load(batchId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(
                          ctx,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
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
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sold vs Remaining',
                  style: theme.textTheme.bodySmall,
                ),
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
                child: _metric(
                  theme,
                  'Sold',
                  '${sold.toStringAsFixed(0)} ${batch.quantityUnit}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric(
                  theme,
                  'Remaining',
                  '${remaining.toStringAsFixed(0)} ${batch.quantityUnit}',
                ),
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

  String _purchasePaymentSummary(BatchModel batch) {
    final mode = batch.purchasePaymentMode ?? 'cash';
    final label = switch (mode) {
      'credit' => 'Purchase on credit',
      'part_credit' => 'Part cash / part credit',
      _ => 'Paid in cash',
    };
    final remaining = (batch.totalPurchaseCost - batch.purchaseAmountPaid)
        .clamp(0, double.infinity);
    if (batch.purchaseAmountPaid > 0) {
      return '$label — paid ${CurrencyFormatter.format(batch.purchaseAmountPaid)}, '
          'remaining ${CurrencyFormatter.format(remaining)}';
    }
    if (mode == 'credit') {
      return '$label — full ${CurrencyFormatter.format(remaining)} outstanding';
    }
    return label;
  }

  Widget _metric(ThemeData theme, String label, String value) {
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
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  IconData _paymentIcon(String mode) {
    switch (mode) {
      case 'cash':
        return MingCuteIcons.mgc_wallet_3_line;
      case 'credit':
        return MingCuteIcons.mgc_time_line;
      case 'bank_transfer':
        return MingCuteIcons.mgc_bank_line;
      case 'partial_credit':
        return MingCuteIcons.mgc_chart_pie_line;
      default:
        return MingCuteIcons.mgc_bill_line;
    }
  }

  Color _paymentColor(ThemeData theme, String mode) {
    switch (mode) {
      case 'cash':
        return theme.colorScheme.primary;
      case 'credit':
        return theme.colorScheme.error;
      case 'bank_transfer':
        return Colors.blue;
      case 'partial_credit':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.outline;
    }
  }
}
