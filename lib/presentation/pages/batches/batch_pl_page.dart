import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../providers/batch_provider.dart';

class BatchPLPage extends StatefulWidget {
  final String batchId;

  const BatchPLPage({super.key, required this.batchId});

  @override
  State<BatchPLPage> createState() => _BatchPLPageState();
}

class _BatchPLPageState extends State<BatchPLPage> {
  String get batchId => widget.batchId;

  @override
  void initState() {
    super.initState();
    context.read<BatchDetailProvider>().load(batchId);
    context.read<BatchPLProvider>().load(batchId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchProvider = context.watch<BatchDetailProvider>();
    final plProvider = context.watch<BatchPLProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch P&L'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export available in a later build')),
              );
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: _buildBody(context, theme, batchProvider, plProvider),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, BatchDetailProvider batchProvider, BatchPLProvider plProvider) {
    final batch = batchProvider.batch;
    if (batch == null) {
      if (batchProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (batchProvider.error != null) {
        return _errorBlock(context, batchProvider.error!, () => context.read<BatchDetailProvider>().load(batchId));
      }
      return const Center(child: Text('No batch data'));
    }

    final pl = plProvider.pl;
    if (pl == null) {
      if (plProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (plProvider.error != null) {
        return _errorBlock(context, plProvider.error!, () => context.read<BatchPLProvider>().load(batchId));
      }
      return const Center(child: Text('No P&L data yet'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(batch.batchCode, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          '${batch.productName ?? 'Product'} • ${batch.totalQuantity.toStringAsFixed(0)} ${batch.quantityUnit}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _section(theme, 'Cost Breakdown', [
          _line('Purchase Cost', pl.costBreakdown.purchaseCost),
          _line('Purchaser Daily Charges', pl.costBreakdown.purchaserDailyCharges),
          _line('Purchaser Expenses', pl.costBreakdown.purchaserExpenses),
          _line('Packing Cost', pl.costBreakdown.packingCost),
          _line('Transport Cost', pl.costBreakdown.transportCost),
          _line('Seller Daily Charges', pl.costBreakdown.sellerDailyCharges),
          _line('Seller Expenses', pl.costBreakdown.sellerExpenses),
          _line('Total Cost', pl.costBreakdown.totalCost, emphasize: true),
        ]),
        const SizedBox(height: 16),
        _section(theme, 'Revenue', [
          _line('Total Revenue', pl.revenue.totalRevenue),
          _line('Cash Received', pl.revenue.cashReceived),
          _line('Credit Outstanding', pl.revenue.creditOutstanding),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Profit / Loss', style: theme.textTheme.titleMedium),
              Text(
                CurrencyFormatter.format(pl.netProfitLoss),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: pl.netProfitLoss >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorBlock(BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _line(String label, double value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500))),
          Text(CurrencyFormatter.format(value), style: TextStyle(fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}
