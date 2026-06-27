import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/amount_text.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/report_model.dart';

class PLReportPage extends ConsumerStatefulWidget {
  const PLReportPage({super.key});

  @override
  ConsumerState<PLReportPage> createState() => _PLReportPageState();
}

class _PLReportPageState extends ConsumerState<PLReportPage> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';

    final params = <String, dynamic>{
      'business_id': businessId,
      if (_dateRange != null) 'date_from': '${_dateRange!.start.year}-${_dateRange!.start.month.toString().padLeft(2, '0')}-${_dateRange!.start.day.toString().padLeft(2, '0')}',
      if (_dateRange != null) 'date_to': '${_dateRange!.end.year}-${_dateRange!.end.month.toString().padLeft(2, '0')}-${_dateRange!.end.day.toString().padLeft(2, '0')}',
    };

    final plAsync = ref.watch(plSummaryProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('P&L Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) setState(() => _dateRange = picked);
            },
          ),
        ],
      ),
      body: plAsync.when(
        data: (pl) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('P&L Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _PLRow('Total Batches', pl.totalBatches.toString()),
                    _PLRow('Total Cost', CurrencyFormatter.format(pl.totalCost)),
                    _PLRow('Total Revenue', CurrencyFormatter.format(pl.totalRevenue)),
                    const Divider(thickness: 2),
                    Text(
                      'Net ${pl.totalProfitLoss >= 0 ? 'Profit' : 'Loss'}: ${CurrencyFormatter.format(pl.totalProfitLoss)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: pl.totalProfitLoss >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Batch Details', style: TextStyle(fontWeight: FontWeight.w600)),
            ...pl.batchSummaries.map((batch) => Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                title: Text(batch.batchCode ?? batch.batchId),
                subtitle: Text('Cost: ${CurrencyFormatter.format(batch.costBreakdown.totalCost)}'),
                trailing: AmountText(
                  amount: batch.netProfitLoss,
                  fontSize: 14,
                  color: batch.netProfitLoss >= 0 ? Colors.green : Colors.red,
                ),
              ),
            )),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _PLRow extends StatelessWidget {
  final String label;
  final String value;
  const _PLRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
