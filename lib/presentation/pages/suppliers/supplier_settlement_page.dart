import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
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
import '../../widgets/suppliers/supplier_batch_summary_card.dart';
import '../../widgets/suppliers/supplier_header_card.dart';
import '../../widgets/suppliers/supplier_outstanding_card.dart';
import 'supplier_ledger_page.dart';

enum _DateRange { all, today, sevenDays, thirtyDays, custom }

class SupplierSettlementPage extends StatefulWidget {
  const SupplierSettlementPage({super.key});

  @override
  State<SupplierSettlementPage> createState() => _SupplierSettlementPageState();
}

class _SupplierSettlementPageState extends State<SupplierSettlementPage> {
  final _searchCtrl = TextEditingController();
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_paymentsChannel != null) {
      SupabaseService.instance.client.removeChannel(_paymentsChannel!);
    }
    super.dispose();
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
    final allOutstanding = provider.outstanding;
    final totalOutstanding = allOutstanding.fold<double>(
      0,
      (s, o) => s + o.outstanding,
    );
    final totalDue = allOutstanding.fold<double>(0, (s, o) => s + o.totalDue);
    final totalPaid = allOutstanding.fold<double>(0, (s, o) => s + o.totalPaid);

    final query = _searchCtrl.text.trim().toLowerCase();
    final outstanding = query.isEmpty
        ? allOutstanding
        : allOutstanding.where((s) {
            final name = s.supplierName.toLowerCase();
            return name.contains(query);
          }).toList();

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
            SupplierHeaderCard(
              title: 'Supplier payables',
              subtitle:
                  'Track what you owe each supplier from multi-supplier batch purchases and record payments — same workflow as customer credit.',
              metrics: [
                buildSupplierMetric(
                  theme,
                  'Total due',
                  CurrencyFormatter.format(totalDue),
                ),
                buildSupplierMetric(
                  theme,
                  'Total paid',
                  CurrencyFormatter.format(totalPaid),
                ),
                buildSupplierMetric(
                  theme,
                  'Outstanding',
                  CurrencyFormatter.format(totalOutstanding),
                  color: totalOutstanding > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search suppliers by name',
                prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(HeroIcons.x_mark, size: 20),
                        onPressed: () => setState(() => _searchCtrl.clear()),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildDateFilter(theme),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _showBatches ? 'Purchases by batch' : 'Suppliers',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('By supplier')),
                    ButtonSegment(value: true, label: Text('By batch')),
                  ],
                  selected: {_showBatches},
                  onSelectionChanged: (v) =>
                      setState(() => _showBatches = v.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_showBatches)
              _buildBatchesView(theme, provider)
            else if (outstanding.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: EmptyState(
                  icon: HeroIcons.building_storefront,
                  title: query.isNotEmpty ? 'No matching suppliers' : 'No suppliers yet',
                  subtitle: query.isNotEmpty
                      ? 'Try modifying your search query.'
                      : 'Add multi-supplier purchases in the batch wizard and they will appear here for settlement.',
                ),
              )
            else
              Column(
                children: outstanding
                    .map((s) => SupplierOutstandingCard(
                          supplier: s,
                          onTap: () => _openLedger(s),
                        ))
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

  Widget _buildBatchesView(ThemeData theme, SupplierProvider provider) {
    final summaries = provider.batchSummaries;
    if (summaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: EmptyState(
          icon: HeroIcons.inbox,
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
      children: byBatch.entries
          .map((e) => SupplierBatchSummaryCard(
                batchCode: e.key,
                lines: e.value,
              ))
          .toList(),
    );
  }
}
