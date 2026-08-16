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
    final detailProvider = context.watch<BatchDetailProvider>();
    final saleProvider = context.watch<SaleProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    if (plProvider.isLoading && detailProvider.batch == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final pl = plProvider.pl;
    final batch = detailProvider.batch;

    final double purchaseCost = pl?.costBreakdown.purchaseCost ??
        (batch?.totalPurchaseCost ?? 0.0);
    final double purchaserDaily = pl?.costBreakdown.purchaserDailyCharges ??
        detailProvider.batchPartners
            .where((p) => p['role'] == 'purchaser')
            .fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final double purchaserExpenses = pl?.costBreakdown.purchaserExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'purchaser')
            .fold<double>(0, (s, e) => s + e.amount);
    final double packingCost = pl?.costBreakdown.packingCost ??
        detailProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final double transportCost = pl?.costBreakdown.transportCost ??
        detailProvider.vehicleLoads.fold<double>(
          0,
          (s, l) => s + l.totalCost,
        );
    final int transportVehicleCount = detailProvider.vehicleLoads
        .map((l) => l.vehicleId)
        .toSet()
        .length;
    final int transportLoadCount = detailProvider.vehicleLoads.length;
    final String transportLabel = transportLoadCount > 0
        ? 'Transport ($transportVehicleCount vehicle${transportVehicleCount == 1 ? '' : 's'} · '
            '$transportLoadCount load${transportLoadCount == 1 ? '' : 's'})'
        : 'Transport';
    final double sellerDaily = pl?.costBreakdown.sellerDailyCharges ??
        detailProvider.batchPartners
            .where((p) => p['role'] == 'seller' || p['role'] == 'both')
            .fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final double sellerExpenses = pl?.costBreakdown.sellerExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'seller')
            .fold<double>(0, (s, e) => s + e.amount);

    final double totalCost = pl?.costBreakdown.totalCost ??
        (purchaseCost +
            purchaserDaily +
            purchaserExpenses +
            packingCost +
            transportCost +
            sellerDaily +
            sellerExpenses);

    final double totalRevenue = pl?.revenue.totalRevenue ??
        saleProvider.sales.fold<double>(0, (s, e) => s + e.totalAmount);
    final double cashReceived = pl?.revenue.cashReceived ??
        saleProvider.sales.fold<double>(
          0,
          (s, e) =>
              s +
              (e.cashReceived > 0
                  ? e.cashReceived
                  : (e.paymentMode == 'cash' ? e.totalAmount : 0.0)),
        );
    final double creditOutstanding = pl?.revenue.creditOutstanding ??
        (totalRevenue - cashReceived).clamp(0, double.infinity).toDouble();

    final double netProfitLoss = pl?.netProfitLoss ?? (totalRevenue - totalCost);

    return RefreshIndicator(
      onRefresh: () async {
        if (batch != null) {
          await Future.wait([
            context.read<BatchPLProvider>().load(batch.id),
            context.read<BatchDetailProvider>().load(batch.id),
            context.read<SaleProvider>().loadByBatch(batch.id),
            context.read<ExpenseProvider>().load(batch.id),
          ]);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  netProfitLoss >= 0
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.error.withValues(alpha: 0.12),
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
                Text('Net Profit & Loss', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(netProfitLoss),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: netProfitLoss >= 0
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
          buildBatchCostLine(theme, 'Purchase Cost', purchaseCost),
          buildBatchCostLine(
            theme,
            'Purchaser Daily Charges',
            purchaserDaily,
          ),
          buildBatchCostLine(
            theme,
            'Purchaser Expenses',
            purchaserExpenses,
          ),
          buildBatchCostLine(theme, 'Packing Cost', packingCost),
          buildBatchCostLine(theme, transportLabel, transportCost),
          buildBatchCostLine(
            theme,
            'Seller Daily Charges',
            sellerDaily,
          ),
          buildBatchCostLine(theme, 'Seller Expenses', sellerExpenses),
          const Divider(height: 20),
          buildBatchCostLine(theme, 'TOTAL COST', totalCost, bold: true),
          const SizedBox(height: 16),
          _sectionHeader(theme, 'Revenue'),
          buildBatchCostLine(theme, 'Total Revenue', totalRevenue),
          buildBatchCostLine(theme, 'Cash Received', cashReceived),
          buildBatchCostLine(theme, 'Credit Outstanding', creditOutstanding),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: theme.textTheme.titleLarge),
      );
}
