import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'supplier_ledger_page.dart';

enum _DateRange { all, today, sevenDays, thirtyDays, custom }

class SupplierSettlementPage extends StatefulWidget {
  const SupplierSettlementPage({super.key});

  @override
  State<SupplierSettlementPage> createState() => _SupplierSettlementPageState();
}

class _SupplierSettlementPageState extends State<SupplierSettlementPage> {
  RealtimeChannel? _paymentsChannel;

  _DateRange _range = _DateRange.all;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _showBatches = false;

  String get _businessId => context.read<AuthProvider>().businessId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _businessId;
      if (id.isNotEmpty) {
        _reload(id);
        _subscribe(id);
      }
    });
  }

  Future<void> _reload(String businessId) async {
    final from = _from;
    final to = _to;
    await Future.wait([
      context.read<SupplierProvider>().loadOutstanding(
        businessId,
        from: from,
        to: to,
      ),
      context.read<SupplierProvider>().loadBatchSummaries(
        businessId,
        from: from,
        to: to,
      ),
    ]);
  }

  DateTime? get _from {
    switch (_range) {
      case _DateRange.all:
        return null;
      case _DateRange.today:
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
      case _DateRange.sevenDays:
        return DateTime.now().subtract(const Duration(days: 6));
      case _DateRange.thirtyDays:
        return DateTime.now().subtract(const Duration(days: 29));
      case _DateRange.custom:
        return _customFrom;
    }
  }

  DateTime? get _to => _range == _DateRange.custom ? _customTo : null;

  void _setRange(_DateRange r) {
    setState(() => _range = r);
    final id = _businessId;
    if (id.isNotEmpty) _reload(id);
  }

  Future<void> _pickCustomFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Filter from',
    );
    if (picked == null) return;
    setState(() {
      _customFrom = picked;
      _range = _DateRange.custom;
    });
    final id = _businessId;
    if (id.isNotEmpty) _reload(id);
  }

  Future<void> _pickCustomTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Filter to',
    );
    if (picked == null) return;
    setState(() {
      _customTo = picked;
      _range = _DateRange.custom;
    });
    final id = _businessId;
    if (id.isNotEmpty) _reload(id);
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
            if (mounted) _reload(businessId);
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
            if (mounted) _reload(businessId);
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
    await context.read<SupplierProvider>().loadLedger(
      id,
      s.supplierName,
      from: _from,
      to: _to,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierLedgerPage(
          supplierName: s.supplierName,
          from: _from,
          to: _to,
        ),
      ),
    );
    if (!mounted) return;
    _reload(id);
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
    final totalPaid = outstanding.fold<double>(0, (s, o) => s + o.totalPaid);

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Settlements')),
      body: RefreshIndicator(
        onRefresh: () async {
          final id = _businessId;
          if (id.isNotEmpty) await _reload(id);
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
                      _metric(
                        theme,
                        'Total due',
                        CurrencyFormatter.format(totalDue),
                      ),
                      _metric(
                        theme,
                        'Total paid',
                        CurrencyFormatter.format(totalPaid),
                      ),
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
            const SizedBox(height: 16),
            _buildDateFilter(theme),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.storefront_outlined, size: 18),
                  label: Text('Suppliers'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text('By batch'),
                ),
              ],
              selected: {_showBatches},
              onSelectionChanged: (s) => setState(() => _showBatches = s.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
              ),
            ),
            const SizedBox(height: 16),
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
                      onPressed: () {
                        final id = _businessId;
                        if (id.isNotEmpty) _reload(id);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_showBatches)
              _buildBatchesView(theme, provider)
            else if (outstanding.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: MingCuteIcons.mgc_store_2_line,
                  title: 'No suppliers yet',
                  subtitle:
                      'Add multi-supplier purchases in the batch wizard and they will appear here for settlement.',
                ),
              )
            else
              Column(
                children: outstanding
                    .map((s) => _supplierCard(theme, s))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(ThemeData theme) {
    Widget chip(String label, _DateRange value) {
      final selected = _range == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => _setRange(value),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date range', style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('All time', _DateRange.all),
              const SizedBox(width: 8),
              chip('Today', _DateRange.today),
              const SizedBox(width: 8),
              chip('7 days', _DateRange.sevenDays),
              const SizedBox(width: 8),
              chip('30 days', _DateRange.thirtyDays),
              const SizedBox(width: 8),
              chip('Custom', _DateRange.custom),
            ],
          ),
        ),
        if (_range == _DateRange.custom) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.event, size: 16),
                label: Text(
                  _customFrom == null
                      ? 'From: pick date'
                      : 'From: ${DateFormatter.toDDMMYYYY(_customFrom!)}',
                ),
                onPressed: _pickCustomFrom,
              ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 16),
                label: Text(
                  _customTo == null
                      ? 'To: pick date'
                      : 'To: ${DateFormatter.toDDMMYYYY(_customTo!)}',
                ),
                onPressed: _pickCustomTo,
              ),
              if (_customFrom != null || _customTo != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _customFrom = null;
                      _customTo = null;
                      _range = _DateRange.all;
                    });
                    final id = _businessId;
                    if (id.isNotEmpty) _reload(id);
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _supplierCard(ThemeData theme, SupplierOutstanding s) {
    return GreenCard(
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
              color: s.outstanding > 0 ? AppColors.error : AppColors.success,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Due ${CurrencyFormatter.format(s.totalDue)} · Paid ${CurrencyFormatter.format(s.totalPaid)}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildBatchesView(ThemeData theme, SupplierProvider provider) {
    final summaries = provider.batchSummaries;
    if (summaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: EmptyState(
          icon: MingCuteIcons.mgc_inbox_line,
          title: 'No purchases',
          subtitle: 'No batch purchases found for the selected range.',
        ),
      );
    }

    final byBatch = <String, List<SupplierBatchSummary>>{};
    for (final s in summaries) {
      byBatch.putIfAbsent(s.batchCode, () => []).add(s);
    }

    return Column(
      children: byBatch.entries.map((e) {
        final lines = e.value;
        final batchCode = e.key;
        final purchaseDate = lines.first.purchaseDate;
        final debt = lines.fold<double>(0, (s, l) => s + l.debt);
        final paid = lines.fold<double>(0, (s, l) => s + l.paidAtPurchase);
        final remaining = lines.fold<double>(0, (s, l) => s + l.remaining);

        return GreenCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    MingCuteIcons.mgc_inbox_2_line,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      batchCode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    purchaseDate.isEmpty
                        ? ''
                        : DateFormatter.toDDMMYYYY(
                            DateTime.tryParse(purchaseDate) ?? DateTime(2000),
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Debt ${CurrencyFormatter.format(debt)} · Paid ${CurrencyFormatter.format(paid)}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Remaining ${CurrencyFormatter.format(remaining)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: remaining > 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lines[i].supplierName,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Due ${CurrencyFormatter.format(lines[i].debt)} · Paid ${CurrencyFormatter.format(lines[i].paidAtPurchase)}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        CurrencyFormatter.format(lines[i].remaining),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: lines[i].remaining > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${lines.length} supplier${lines.length == 1 ? '' : 's'} in this batch',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      MingCuteIcons.mgc_right_line,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _metric(ThemeData theme, String label, String value, {Color? color}) {
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
