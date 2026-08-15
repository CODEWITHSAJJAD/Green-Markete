import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/export/bill_export.dart';
import '../../../core/export/bill_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/batch_provider.dart';
import '../../providers/business_provider.dart';

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
    context.read<ExpenseProvider>().load(batchId);
    context.read<SaleProvider>().loadByBatch(batchId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchProvider = context.watch<BatchDetailProvider>();
    final plProvider = context.watch<BatchPLProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final saleProvider = context.watch<SaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch P&L'),
        actions: [
          IconButton(
            tooltip: 'Share bill',
            onPressed: () => _shareBill(
              context,
              batchProvider,
              plProvider,
              expenseProvider,
              saleProvider,
            ),
            icon: const Icon(MingCuteIcons.mgc_share_2_line),
          ),
        ],
      ),
      body: _buildBody(
        context,
        theme,
        batchProvider,
        plProvider,
        expenseProvider,
        saleProvider,
      ),
    );
  }

  Future<void> _shareBill(
    BuildContext context,
    BatchDetailProvider batchProvider,
    BatchPLProvider plProvider,
    ExpenseProvider expenseProvider,
    SaleProvider saleProvider,
  ) async {
    final batch = batchProvider.batch;
    if (batch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch data not ready yet')),
      );
      return;
    }

    final pl = plProvider.pl;
    final double purchaseCost = pl?.costBreakdown.purchaseCost ?? batch.totalPurchaseCost;
    final double purchaserDaily = pl?.costBreakdown.purchaserDailyCharges ??
        batchProvider.batchPartners
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
        batchProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final double transportCost = pl?.costBreakdown.transportCost ??
        batchProvider.vehicleLoads.fold<double>(
          0,
          (s, l) => s + l.totalCost,
        );
    final double sellerDaily = pl?.costBreakdown.sellerDailyCharges ??
        batchProvider.batchPartners
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

    final party = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Bill for'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'Seller'),
            child: const Text('Seller — bill of sales with total expenses'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'Purchaser'),
            child: const Text('Purchaser — purchase bill'),
          ),
        ],
      ),
    );
    if (party == null || !context.mounted) return;
    final businessName = context.read<BusinessProvider>().business?.name;
    final bill = BillModel(
      documentTitle: '$party Bill',
      businessName: businessName,
      header: [
        BillHeaderLine('Batch Code', batch.batchCode),
        BillHeaderLine('Product', batch.productName ?? ''),
        BillHeaderLine(
          'Quantity',
          '${batch.totalQuantity.toStringAsFixed(0)} ${batch.quantityUnit}',
        ),
        BillHeaderLine('Status', batch.status),
        BillHeaderLine('Purchase Date', DateFormatter.display(batch.purchaseDate)),
      ],
      sections: [
        BillSection('Cost Breakdown', [
          BillLine('Purchase Cost', CurrencyFormatter.format(purchaseCost)),
          BillLine('Purchaser Daily Charges', CurrencyFormatter.format(purchaserDaily)),
          BillLine('Purchaser Expenses', CurrencyFormatter.format(purchaserExpenses)),
          BillLine('Packing Cost', CurrencyFormatter.format(packingCost)),
          BillLine('Transport Cost', CurrencyFormatter.format(transportCost)),
          BillLine('Seller Daily Charges', CurrencyFormatter.format(sellerDaily)),
          BillLine('Seller Expenses', CurrencyFormatter.format(sellerExpenses)),
          BillLine('Total Cost', CurrencyFormatter.format(totalCost), emphasize: true),
        ]),
        BillSection('Revenue', [
          BillLine('Total Revenue', CurrencyFormatter.format(totalRevenue)),
          BillLine('Cash Received', CurrencyFormatter.format(cashReceived)),
          BillLine('Credit Outstanding', CurrencyFormatter.format(creditOutstanding)),
        ]),
      ],
      total: BillLine('Net Profit / Loss', CurrencyFormatter.format(netProfitLoss), emphasize: true),
      footer: 'Generated by Green Market on ${DateFormatter.toDDMMYYYY(DateTime.now())}. '
          'Amounts in ${CurrencyFormatter.currentCode}.',
    );
    await shareBill(
      context,
      bill: bill,
      fileName: '${batch.batchCode}_${party}_bill',
      subject: 'Green Market — ${batch.batchCode} $party bill',
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    BatchDetailProvider batchProvider,
    BatchPLProvider plProvider,
    ExpenseProvider expenseProvider,
    SaleProvider saleProvider,
  ) {
    final batch = batchProvider.batch;
    if (batch == null) {
      if (batchProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (batchProvider.error != null) {
        return _errorBlock(
          context,
          batchProvider.error!,
          () => context.read<BatchDetailProvider>().load(batchId),
        );
      }
      return const Center(child: Text('No batch data'));
    }

    final pl = plProvider.pl;

    final double purchaseCost = pl?.costBreakdown.purchaseCost ?? batch.totalPurchaseCost;
    final double purchaserDaily = pl?.costBreakdown.purchaserDailyCharges ??
        batchProvider.batchPartners
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
        batchProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final double transportCost = pl?.costBreakdown.transportCost ??
        batchProvider.vehicleLoads.fold<double>(
          0,
          (s, l) => s + l.totalCost,
        );
    final double sellerDaily = pl?.costBreakdown.sellerDailyCharges ??
        batchProvider.batchPartners
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
        await Future.wait([
          context.read<BatchDetailProvider>().load(batchId),
          context.read<BatchPLProvider>().load(batchId),
          context.read<ExpenseProvider>().load(batchId),
          context.read<SaleProvider>().loadByBatch(batchId),
        ]);
      },
      child: ListView(
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
            _line('Purchase Cost', purchaseCost),
            _line('Purchaser Daily Charges', purchaserDaily),
            _line('Purchaser Expenses', purchaserExpenses),
            _line('Packing Cost', packingCost),
            _line('Transport Cost', transportCost),
            _line('Seller Daily Charges', sellerDaily),
            _line('Seller Expenses', sellerExpenses),
            _line('Total Cost', totalCost, emphasize: true),
          ]),
          const SizedBox(height: 16),
          _section(theme, 'Revenue', [
            _line('Total Revenue', totalRevenue),
            _line('Cash Received', cashReceived),
            _line('Credit Outstanding', creditOutstanding),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Profit / Loss', style: theme.textTheme.titleMedium),
                Text(
                  CurrencyFormatter.format(netProfitLoss),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: netProfitLoss >= 0 ? AppColors.profit : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
