import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capability.dart';
import '../../providers/data_refresh.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/suppliers/supplier_header_card.dart';
import '../../widgets/suppliers/supplier_ledger_tile.dart';
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
          SupplierHeaderCard(
            title: _supplierName,
            subtitle: 'Supplier statement',
            metrics: [
              buildSupplierMetric(
                theme,
                'Purchases',
                CurrencyFormatter.format(totalPurchases),
              ),
              buildSupplierMetric(
                theme,
                'Paid',
                CurrencyFormatter.format(totalPayments),
              ),
              buildSupplierMetric(
                theme,
                'Outstanding',
                CurrencyFormatter.format(outstanding),
                color: outstanding > 0 ? AppColors.error : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilter(theme),
          const SizedBox(height: 16),
          Text('Ledger entries', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ledger.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No transactions found for this supplier.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...ledger.map((e) => SupplierLedgerTile(entry: e)),
        ],
      ),
    );
  }

  Widget _buildFilter(ThemeData theme) {
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
        Text('Filter range', style: theme.textTheme.labelMedium),
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
}
