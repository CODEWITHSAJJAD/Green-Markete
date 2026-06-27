import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../providers/batch_provider.dart';
import '../../widgets/amount_text.dart';
import '/core/utils/currency_formatter.dart';

class BatchPLPage extends ConsumerWidget {
  final String batchId;
  const BatchPLPage({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plAsync = ref.watch(batchPLProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'Batch P&L Report'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {},
          ),
        ],
      ),
      body: plAsync.when(
        data: (pl) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pl.batchCode != null)
                Text('Batch: ${pl.batchCode}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('COST BREAKDOWN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Divider(),
              _PLRow('Purchase Cost', pl.costBreakdown.purchaseCost),
              _PLRow('Purchaser Daily Charges', pl.costBreakdown.purchaserDailyCharges),
              _PLRow('Purchaser Expenses', pl.costBreakdown.purchaserExpenses),
              _PLRow('Packing Cost', pl.costBreakdown.packingCost),
              _PLRow('Transport Cost', pl.costBreakdown.transportCost),
              _PLRow('Seller Daily Charges', pl.costBreakdown.sellerDailyCharges),
              _PLRow('Seller Expenses', pl.costBreakdown.sellerExpenses),
              const Divider(thickness: 2),
              _PLRow('TOTAL COST', pl.costBreakdown.totalCost, isBold: true),
              const SizedBox(height: 24),
              const Text('SALES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Divider(),
              _PLRow('Total Revenue', pl.revenue.totalRevenue, color: Colors.green),
              _PLRow('Cash Received', pl.revenue.cashReceived),
              _PLRow('Credit Outstanding', pl.revenue.creditOutstanding, color: Colors.amber),
              const Divider(thickness: 2),
              _PLRow(
                pl.netProfitLoss >= 0 ? 'NET PROFIT' : 'NET LOSS',
                pl.netProfitLoss,
                isBold: true,
                color: pl.netProfitLoss >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _PLRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final Color? color;

  const _PLRow(this.label, this.amount, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color,
          )),
          AmountText(
            amount: amount,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}
