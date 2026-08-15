import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/date_range_filter_button.dart';

class PartnerBalancePage extends StatefulWidget {
  final String partnerId;
  final PartnerModel? partner;

  const PartnerBalancePage({super.key, required this.partnerId, this.partner});

  @override
  State<PartnerBalancePage> createState() => _PartnerBalancePageState();
}

class _PartnerBalancePageState extends State<PartnerBalancePage> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().loadLedger(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partner?.fullName ?? 'Partner Balance'),
        actions: [
          DateRangeFilterButton(
            value: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
        ],
      ),
      body: transactionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(transactionProvider.error.toString()),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.read<TransactionProvider>().loadLedger(widget.partnerId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildLedger(context, theme, transactionProvider),
    );
  }

  Widget _buildLedger(BuildContext context, ThemeData theme, TransactionProvider transactionProvider) {
    final ledger = transactionProvider.ledger ?? {};
    final data = (ledger['data'] as Map<String, dynamic>?) ?? ledger;
    final entries = ((data['entries'] as List<dynamic>?) ??
            (ledger['entries'] as List<dynamic>?) ??
            [])
        .where((entry) {
      if (_range == null) return true;
      final dateStr = entry['date']?.toString() ?? '';
      final d = DateTime.tryParse(dateStr);
      if (d == null) return true;
      return !d.isBefore(_range!.start) && !d.isAfter(_range!.end);
    }).toList();
    final balance = (data['balance'] as Map<String, dynamic>?) ??
        (ledger['balance'] as Map<String, dynamic>?) ??
        {};
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Net Balance', style: theme.textTheme.titleMedium),
                  ),
                  if (_range != null)
                    Chip(
                      label: Text(
                        '${_range!.start.toString().split(' ').first} → ${_range!.end.toString().split(' ').first}',
                      ),
                      onDeleted: () => setState(() => _range = null),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format((balance['net_balance'] as num?)?.toDouble() ?? 0),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text('Total Sent: ${CurrencyFormatter.format((balance['total_sent'] as num?)?.toDouble() ?? 0)}'),
              Text('Total Received: ${CurrencyFormatter.format((balance['total_received'] as num?)?.toDouble() ?? 0)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No transactions in this date range',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...entries.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(entry['description']?.toString() ?? '-'),
                subtitle: Text('${entry['date'] ?? '-'} • ${entry['type'] ?? '-'}'),
                trailing: Text(CurrencyFormatter.format((entry['amount'] as num?)?.toDouble() ?? 0)),
              ),
            ),
          ),
      ],
    );
  }
}
