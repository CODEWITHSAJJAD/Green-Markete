import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class MarketPerformancePage extends StatefulWidget {
  const MarketPerformancePage({super.key});

  @override
  State<MarketPerformancePage> createState() => _MarketPerformancePageState();
}

class _MarketPerformancePageState extends State<MarketPerformancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<ReportProvider>().loadMarketPerformance(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Market Performance')),
      body: report.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(report.error!),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : report.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildList(report.marketPerformance),
    );
  }

  Widget _buildList(List<MarketPerformanceModel> markets) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: markets.length,
      itemBuilder: (context, index) {
        final market = markets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(market.marketName),
            subtitle: Text('${market.city} • ${market.batchCount} batches'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.format(market.profitLoss)),
                Text(
                  'Rev ${CurrencyFormatter.formatCompact(market.totalRevenue)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
