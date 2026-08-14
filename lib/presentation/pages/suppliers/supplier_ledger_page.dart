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
import '../../providers/capability.dart';
import '../../providers/data_refresh.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/green_card.dart';
import 'record_supplier_payment_page.dart';

enum _LedgerRange { all, sevenDays, thirtyDays, custom }

class SupplierLedgerPage extends StatefulWidget {
  final String supplierName;
  final DateTime? from;
  final DateTime? to;

  const SupplierLedgerPage({
    super.key,
    required this.supplierName,
    this.from,
    this.to,
  });

  @override
  State<SupplierLedgerPage> createState() => _SupplierLedgerPageState();
}

class _SupplierLedgerPageState extends State<SupplierLedgerPage> {
  RealtimeChannel? _channel;

  _LedgerRange _range = _LedgerRange.all;
  DateTime? _customFrom;
  DateTime? _customTo;

  String get _businessId => context.read<AuthProvider>().businessId ?? '';
  String get _supplierName => widget.supplierName;

  DateTime? get _from {
    switch (_range) {
      case _LedgerRange.all:
        return null;
      case _LedgerRange.sevenDays:
        return DateTime.now().subtract(const Duration(days: 6));
      case _LedgerRange.thirtyDays:
        return DateTime.now().subtract(const Duration(days: 29));
      case _LedgerRange.custom:
        return _customFrom;
    }
  }

  DateTime? get _to => _range == _LedgerRange.custom ? _customTo : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _businessId;
      if (id.isNotEmpty) {
        _load(id);
        _subscribe(id);
      }
    });
  }

  void _load(String businessId) {
    context.read<SupplierProvider>().loadLedger(
      businessId,
      _supplierName,
      from: _from,
      to: _to,
    );
  }

  void _setRange(_LedgerRange r) {
    setState(() => _range = r);
    final id = _businessId;
    if (id.isNotEmpty) _load(id);
  }

  Future<void> _pickCustom({required bool from}) async {
    final initial = from
        ? (_customFrom ?? DateTime.now())
        : (_customTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: from ? 'Filter from' : 'Filter to',
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _customFrom = picked;
      } else {
        _customTo = picked;
      }
      _range = _LedgerRange.custom;
    });
    final id = _businessId;
    if (id.isNotEmpty) _load(id);
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
            if (mounted) _load(businessId);
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
            if (mounted) _load(businessId);
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
        : (provider.ledger.last.runningBalance.clamp(
            0,
            double.infinity,
          )).toDouble();
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
      floatingActionButton: outstanding > 0 &&
              context.read<AuthProvider>().capabilities.can(Capability.manageSupplier)
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('Supplier statement', style: theme.textTheme.bodyMedium),
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
          const SizedBox(height: 16),
          _buildDateFilter(theme),
          const SizedBox(height: 16),
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
              child: Text('No purchases or payments in this range.'),
            )
          else
            Column(children: ledger.map((e) => _ledgerCard(theme, e)).toList()),
        ],
      ),
    );
  }

  Widget _buildDateFilter(ThemeData theme) {
    Widget chip(String label, _LedgerRange value) {
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
              chip('All time', _LedgerRange.all),
              const SizedBox(width: 8),
              chip('7 days', _LedgerRange.sevenDays),
              const SizedBox(width: 8),
              chip('30 days', _LedgerRange.thirtyDays),
              const SizedBox(width: 8),
              chip('Custom', _LedgerRange.custom),
            ],
          ),
        ),
        if (_range == _LedgerRange.custom) ...[
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
                onPressed: () => _pickCustom(from: true),
              ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 16),
                label: Text(
                  _customTo == null
                      ? 'To: pick date'
                      : 'To: ${DateFormatter.toDDMMYYYY(_customTo!)}',
                ),
                onPressed: () => _pickCustom(from: false),
              ),
              if (_customFrom != null || _customTo != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _customFrom = null;
                      _customTo = null;
                      _range = _LedgerRange.all;
                    });
                    final id = _businessId;
                    if (id.isNotEmpty) _load(id);
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _ledgerCard(ThemeData theme, SupplierLedgerEntry e) {
    final isPayment = e.type == 'payment';
    final batchCode = e.batchCode;
    final paidAtPurchase = e.paidAtPurchase;

    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isPayment
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.secondary.withValues(alpha: 0.12),
            child: Icon(
              isPayment
                  ? MingCuteIcons.mgc_arrow_down_line
                  : MingCuteIcons.mgc_arrow_up_line,
              color: isPayment
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.toDDMMYYYY(
                    DateTime.tryParse(e.date) ?? DateTime(2000),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                if (batchCode != null && batchCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      batchCode,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (!isPayment) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Debt ${CurrencyFormatter.format(e.amount)} · Paid ${CurrencyFormatter.format(paidAtPurchase)} · Remaining ${CurrencyFormatter.format((e.amount - paidAtPurchase).clamp(0, double.infinity))}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(e.amount),
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: ${CurrencyFormatter.format(e.runningBalance.clamp(0, double.infinity))}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value, {Color? color}) {
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
