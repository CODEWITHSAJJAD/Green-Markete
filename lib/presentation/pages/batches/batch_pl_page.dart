import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/export/bill_export.dart';
import '../../../core/export/bill_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/batch_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/green_card.dart';

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
    final batchProvider = context.watch<BatchDetailProvider>();
    final plProvider = context.watch<BatchPLProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final saleProvider = context.watch<SaleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Batch P&L Statement',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Bill / Statement',
            onPressed: () => _shareBill(
              context,
              batchProvider,
              plProvider,
              expenseProvider,
              saleProvider,
            ),
            icon: const Icon(HeroIcons.share, size: 20),
          ),
        ],
      ),
      body: _buildBody(
        context,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Batch data not ready yet')));
      return;
    }

    final pl = plProvider.pl;
    final double purchaseCost =
        pl?.costBreakdown.purchaseCost ?? batch.totalPurchaseCost;
    final double purchaserDaily =
        pl?.costBreakdown.purchaserDailyCharges ??
        batchProvider.batchPartners
            .where((p) => p['role'] == 'purchaser')
            .fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final double purchaserExpenses =
        pl?.costBreakdown.purchaserExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'purchaser')
            .fold<double>(0, (s, e) => s + e.amount);
    final double packingCost =
        pl?.costBreakdown.packingCost ??
        batchProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final double transportCost =
        pl?.costBreakdown.transportCost ??
        batchProvider.vehicleLoads.fold<double>(0, (s, l) => s + l.totalCost);
    final double sellerDaily =
        pl?.costBreakdown.sellerDailyCharges ??
        batchProvider.batchPartners
            .where((p) => p['role'] == 'seller' || p['role'] == 'both')
            .fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final double sellerExpenses =
        pl?.costBreakdown.sellerExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'seller')
            .fold<double>(0, (s, e) => s + e.amount);

    final double totalCost =
        pl?.costBreakdown.totalCost ??
        (purchaseCost +
            purchaserDaily +
            purchaserExpenses +
            packingCost +
            transportCost +
            sellerDaily +
            sellerExpenses);

    final double totalRevenue =
        pl?.revenue.totalRevenue ??
        saleProvider.sales.fold<double>(0, (s, e) => s + e.totalAmount);
    final double netProfitLoss =
        pl?.netProfitLoss ?? (totalRevenue - totalCost);

    final party = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Share Statement As',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'purchaser'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Purchaser Bill (Procurement & Logistics)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'seller'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Seller Bill (Market Sales & Dues)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'partner'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Full Comprehensive P&L Statement'),
            ),
          ),
        ],
      ),
    );

    if (party == null || !context.mounted) return;

    final business = context.read<BusinessProvider>().business;
    final businessName = business?.name ?? 'MandiRoznamcha';

    final sections = <BillSection>[
      if (party == 'purchaser' || party == 'partner')
        BillSection('Purchaser Outlay', [
          BillLine('Purchase Cost', CurrencyFormatter.format(purchaseCost)),
          if (purchaserDaily > 0)
            BillLine(
              'Purchaser Daily Charges',
              CurrencyFormatter.format(purchaserDaily),
            ),
          if (purchaserExpenses > 0)
            BillLine(
              'Purchaser Local Expenses',
              CurrencyFormatter.format(purchaserExpenses),
            ),
          if (packingCost > 0)
            BillLine(
              'Packing & Labor Cost',
              CurrencyFormatter.format(packingCost),
            ),
          if (transportCost > 0)
            BillLine(
              'Freight & Transport Cost',
              CurrencyFormatter.format(transportCost),
            ),
        ]),
      if (party == 'seller' || party == 'partner')
        BillSection('Seller Realization', [
          if (sellerDaily > 0)
            BillLine(
              'Seller Daily Charges',
              CurrencyFormatter.format(sellerDaily),
            ),
          if (sellerExpenses > 0)
            BillLine(
              'Seller Market Expenses',
              CurrencyFormatter.format(sellerExpenses),
            ),
          BillLine(
            'Gross Wholesale Revenue',
            CurrencyFormatter.format(totalRevenue),
          ),
        ]),
    ];

    final bill = BillModel(
      documentTitle: 'Batch Statement (${party.toUpperCase()})',
      businessName: businessName,
      header: [
        BillHeaderLine('Batch Code', '#${batch.batchCode}'),
        BillHeaderLine('Product', batch.productName ?? 'Produce'),
        BillHeaderLine('Date', DateFormatter.toDisplay(DateTime.now())),
      ],
      sections: sections,
      total: BillLine(
        party == 'partner'
            ? 'Net Profit / Loss'
            : (party == 'purchaser' ? 'Total Outlay' : 'Net Turnover'),
        CurrencyFormatter.format(
          party == 'partner'
              ? netProfitLoss
              : (party == 'purchaser'
                    ? purchaseCost +
                          purchaserDaily +
                          purchaserExpenses +
                          packingCost +
                          transportCost
                    : totalRevenue - sellerDaily - sellerExpenses),
        ),
        emphasize: true,
      ),
      footer: 'Generated via MandiRoznamcha Wholesale Platform',
    );

    await shareBill(
      context,
      bill: bill,
      fileName: '${batch.batchCode}_${party}_bill',
      subject: 'MandiRoznamcha — ${batch.batchCode} $party bill',
    );
  }

  Widget _buildBody(
    BuildContext context,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
              const SizedBox(height: 12),
              const Text('No batch data available'),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () =>
                    context.read<BatchDetailProvider>().load(batchId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pl = plProvider.pl;

    final double purchaseCost =
        pl?.costBreakdown.purchaseCost ?? batch.totalPurchaseCost;
    final double purchaserDaily =
        pl?.costBreakdown.purchaserDailyCharges ??
        batchProvider.batchPartners
            .where((p) => p['role'] == 'purchaser')
            .fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final double purchaserExpenses =
        pl?.costBreakdown.purchaserExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'purchaser')
            .fold<double>(0, (s, e) => s + e.amount);
    final double packingCost =
        pl?.costBreakdown.packingCost ??
        batchProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final double transportCost =
        pl?.costBreakdown.transportCost ??
        batchProvider.vehicleLoads.fold<double>(0, (s, l) => s + l.totalCost);
    final double sellerDaily =
        pl?.costBreakdown.sellerDailyCharges ??
        batchProvider.batchPartners
            .where((p) => p['role'] == 'seller' || p['role'] == 'both')
            .fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final double sellerExpenses =
        pl?.costBreakdown.sellerExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'seller')
            .fold<double>(0, (s, e) => s + e.amount);

    final double totalCost =
        pl?.costBreakdown.totalCost ??
        (purchaseCost +
            purchaserDaily +
            purchaserExpenses +
            packingCost +
            transportCost +
            sellerDaily +
            sellerExpenses);

    final double totalRevenue =
        pl?.revenue.totalRevenue ??
        saleProvider.sales.fold<double>(0, (s, e) => s + e.totalAmount);
    final double cashReceived =
        pl?.revenue.cashReceived ??
        saleProvider.sales.fold<double>(
          0,
          (s, e) =>
              s +
              (e.cashReceived > 0
                  ? e.cashReceived
                  : (e.paymentMode == 'cash' ? e.totalAmount : 0.0)),
        );
    final double creditOutstanding =
        pl?.revenue.creditOutstanding ??
        (totalRevenue - cashReceived).clamp(0, double.infinity).toDouble();
    final double netProfitLoss =
        pl?.netProfitLoss ?? (totalRevenue - totalCost);
    final isProfit = netProfitLoss >= 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          context.read<BatchDetailProvider>().load(batchId),
          context.read<BatchPLProvider>().load(batchId),
          context.read<ExpenseProvider>().load(batchId),
          context.read<SaleProvider>().loadByBatch(batchId),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(
                    HeroIcons.presentation_chart_bar,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.productName ?? 'Batch Statement',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Batch #${batch.batchCode} • ${batch.totalQuantity.toStringAsFixed(0)} ${batch.quantityUnit}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('Direct & Operational Costs', [
            _line('Procurement Cost', purchaseCost),
            _line('Purchaser Daily Charges', purchaserDaily),
            _line('Purchaser Local Expenses', purchaserExpenses),
            _line('Packing & Labor Cost', packingCost),
            _line('Freight & Transport Cost', transportCost),
            _line('Seller Daily Charges', sellerDaily),
            _line('Seller Market Expenses', sellerExpenses),
            const Divider(height: 16),
            _line('Total Operational Cost', totalCost, bold: true),
          ]),
          const SizedBox(height: 14),
          _section('Wholesale Revenue & Realization', [
            _line('Gross Wholesale Revenue', totalRevenue),
            _line('Cash Received on Counter', cashReceived),
            _line(
              'Outstanding Customer Credit',
              creditOutstanding,
              textColor: AppColors.rose,
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isProfit
                  ? AppColors.emeraldSurface
                  : AppColors.roseSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isProfit
                    ? AppColors.emerald.withValues(alpha: 0.3)
                    : AppColors.rose.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProfit ? 'Net Batch Profit' : 'Net Batch Loss',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: isProfit
                            ? AppColors.emeraldDark
                            : AppColors.rose,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalRevenue > 0
                          ? 'Margin: ${((netProfitLoss / totalRevenue) * 100).toStringAsFixed(1)}%'
                          : 'Pending sales completion',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isProfit
                            ? AppColors.emeraldDark
                            : AppColors.rose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(netProfitLoss),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.3,
                    color: isProfit ? AppColors.emeraldDark : AppColors.rose,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return GreenCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _line(
    String label,
    double amount, {
    bool bold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color:
                  textColor ??
                  (bold ? AppColors.textPrimary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
