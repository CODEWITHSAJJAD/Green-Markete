import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/expense_model.dart';
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

    // Voided expenses are archived-only and must never affect P&L totals.
    // Transport-type expenses are payment records against the already
    // accrued vehicle-load fare (or, if no loads are logged, a standalone
    // transport cost) — they must never also be summed into the generic
    // Purchaser/Seller Expenses totals, or transport cost gets counted twice.
    final activeExpenses = expenseProvider.expenses
        .where((e) => !e.isVoided)
        .toList();
    final nonTransportExpenses = activeExpenses
        .where((e) => e.expenseType != 'transport')
        .toList();

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
    final purchaserExpenseLines = nonTransportExpenses
        .where((e) => e.expenseSide == 'purchaser')
        .toList();
    final double purchaserExpenses = pl?.costBreakdown.purchaserExpenses ??
        purchaserExpenseLines.fold<double>(0, (s, e) => s + e.amount);
    final double packingCost = pl?.costBreakdown.packingCost ??
        detailProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final double vehicleLoadsFare = detailProvider.vehicleLoads.fold<double>(
      0,
      (s, l) => s + l.totalCost,
    );
    final double transportExpenseTotal = activeExpenses
        .where((e) => e.expenseType == 'transport')
        .fold<double>(0, (s, e) => s + e.amount);
    // The accrued fare and the recorded payments against it should match by
    // construction (payments are capped at the remaining fare); take the
    // larger of the two so a standalone transport expense with no logged
    // vehicle load is still counted instead of silently dropped.
    final double transportCost = pl?.costBreakdown.transportCost ??
        (vehicleLoadsFare > transportExpenseTotal
            ? vehicleLoadsFare
            : transportExpenseTotal);
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
    final sellerExpenseLines = nonTransportExpenses
        .where((e) => e.expenseSide == 'seller')
        .toList();
    final double sellerExpenses = pl?.costBreakdown.sellerExpenses ??
        sellerExpenseLines.fold<double>(0, (s, e) => s + e.amount);

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
          _expenseTypeBreakdown(
            theme,
            'Purchaser Expenses',
            purchaserExpenseLines,
            purchaserExpenses,
          ),
          buildBatchCostLine(theme, 'Packing Cost', packingCost),
          buildBatchCostLine(theme, transportLabel, transportCost),
          buildBatchCostLine(
            theme,
            'Seller Daily Charges',
            sellerDaily,
          ),
          _expenseTypeBreakdown(
            theme,
            'Seller Expenses',
            sellerExpenseLines,
            sellerExpenses,
          ),
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

  Widget _expenseTypeBreakdown(
    ThemeData theme,
    String title,
    List<ExpenseModel> lines,
    double total,
  ) {
    if (lines.isEmpty) {
      return buildBatchCostLine(theme, title, total);
    }
    final byType = <String, double>{};
    for (final e in lines) {
      byType[e.expenseType] = (byType[e.expenseType] ?? 0) + e.amount;
    }
    final types = byType.keys.toList()
      ..sort((a, b) => byType[b]!.compareTo(byType[a]!));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                for (final type in types)
                  buildBatchCostLine(
                    theme,
                    _expenseTypeLabel(type),
                    byType[type]!,
                  ),
                buildBatchCostLine(theme, 'Total', total, bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _expenseTypeLabel(String type) {
    switch (type) {
      case 'daily_charge':
        return 'Daily Charge';
      case 'labor':
        return 'Labor';
      case 'accountant':
        return 'Accountant';
      case 'packing':
        return 'Packing';
      case 'stall_fee':
        return 'Stall Fee';
      case 'local_transport':
        return 'Local Transport';
      case 'misc':
        return 'Misc';
      default:
        return type.isEmpty
            ? 'Other'
            : '${type[0].toUpperCase()}${type.substring(1).replaceAll('_', ' ')}';
    }
  }

  Widget _sectionHeader(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: theme.textTheme.titleLarge),
      );
}
