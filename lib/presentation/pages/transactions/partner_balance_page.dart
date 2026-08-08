import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_model.dart';
import '../../providers/transaction_provider.dart';

class PartnerBalancePage extends StatefulWidget {
  final String partnerId;
  final PartnerModel? partner;

  const PartnerBalancePage({super.key, required this.partnerId, this.partner});

  @override
  State<PartnerBalancePage> createState() => _PartnerBalancePageState();
}

class _PartnerBalancePageState extends State<PartnerBalancePage> {
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
      appBar: AppBar(title: Text(widget.partner?.fullName ?? 'Partner Balance')),
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
    final ledger = transactionProvider.ledger;
    final data = ledger?['data'] as Map<String, dynamic>? ?? {};
    final entries = data['entries'] as List<dynamic>? ?? [];
    final balance = data['balance'] as Map<String, dynamic>? ?? {};
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
              Text('Net Balance', style: theme.textTheme.titleMedium),
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
