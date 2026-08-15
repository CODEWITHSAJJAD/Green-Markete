import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../providers/batch_provider.dart';
import 'batch_metric_card.dart';

class BatchPLTab extends StatelessWidget {
  const BatchPLTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        buildBatchCostLine(theme, 'Purchase Cost', pl.costBreakdown.purchaseCost),
        buildBatchCostLine(
          theme,
          'Purchaser Daily Charges',
          pl.costBreakdown.purchaserDailyCharges,
        ),
        buildBatchCostLine(
          theme,
          'Purchaser Expenses',
          pl.costBreakdown.purchaserExpenses,
        ),
        buildBatchCostLine(theme, 'Packing Cost', pl.costBreakdown.packingCost),
        buildBatchCostLine(theme, 'Transport', pl.costBreakdown.transportCost),
        buildBatchCostLine(
          theme,
          'Seller Daily Charges',
          pl.costBreakdown.sellerDailyCharges,
        ),
        buildBatchCostLine(theme, 'Seller Expenses', pl.costBreakdown.sellerExpenses),
        const Divider(),
        buildBatchCostLine(theme, 'TOTAL COST', pl.costBreakdown.totalCost, bold: true),
        const SizedBox(height: 16),
        _sectionHeader(theme, 'Revenue'),
        buildBatchCostLine(theme, 'Total Revenue', pl.revenue.totalRevenue),
        buildBatchCostLine(theme, 'Cash Received', pl.revenue.cashReceived),
        buildBatchCostLine(theme, 'Credit Outstanding', pl.revenue.creditOutstanding),
      ],
    );
  }

  Widget _sectionHeader(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: theme.textTheme.titleLarge),
  );
}
