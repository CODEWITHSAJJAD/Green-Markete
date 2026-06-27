import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/batch_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../providers/batch_provider.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/amount_text.dart';
import '/core/utils/currency_formatter.dart';
import '/core/utils/date_formatter.dart';
import 'widgets/status_timeline.dart';
import 'widgets/expense_entry_sheet.dart';
import 'widgets/sale_entry_sheet.dart';

class BatchDetailPage extends ConsumerStatefulWidget {
  final String batchId;
  const BatchDetailPage({super.key, required this.batchId});

  @override
  ConsumerState<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends ConsumerState<BatchDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    final repo = ref.read(batchRepositoryProvider);
    await repo.updateStatus(widget.batchId, newStatus);
    ref.invalidate(batchDetailProvider(widget.batchId));
    ref.invalidate(batchPLProvider(widget.batchId));
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'purchased': return 'packed';
      case 'packed': return 'in_transit';
      case 'in_transit': return 'delivered';
      case 'delivered': return 'selling';
      case 'selling': return 'closed';
      default: return current;
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchAsync = ref.watch(batchDetailProvider(widget.batchId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Detail'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Packing'),
            Tab(text: 'Sales'),
            Tab(text: 'P&L'),
          ],
        ),
      ),
      body: batchAsync.when(
        data: (batch) => TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(batch: batch, onUpdateStatus: _updateStatus, nextStatus: _nextStatus(batch.status)),
            _ExpensesTab(batchId: widget.batchId),
            _PackingTab(batchId: widget.batchId),
            _SalesTab(batchId: widget.batchId),
            _PLTab(batchId: widget.batchId),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final dynamic batch;
  final Function(String) onUpdateStatus;
  final String nextStatus;

  const _OverviewTab({required this.batch, required this.onUpdateStatus, required this.nextStatus});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(batch.batchCode as String? ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StatusTimeline(currentStatus: batch.status as String? ?? 'purchased'),
                const SizedBox(height: 16),
                if (batch.status != 'closed')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onUpdateStatus(nextStatus),
                      child: Text('Mark as ${nextStatus[0].toUpperCase()}${nextStatus.substring(1)}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Divider(),
                _InfoRow(label: 'Product ID', value: batch.productId as String? ?? '-'),
                _InfoRow(label: 'Quantity', value: '${batch.totalQuantity ?? '-'} ${batch.quantityUnit ?? ''}'),
                _InfoRow(label: 'Status', value: batch.status as String? ?? '-'),
                _InfoRow(label: 'Purchase Date', value: batch.purchaseDate as String? ?? '-'),
                _InfoRow(label: 'Total Cost', value: CurrencyFormatter.format((batch.totalPurchaseCost as num?)?.toDouble() ?? 0)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final String batchId;
  const _ExpensesTab({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(batchExpensesProvider(batchId));
    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) => expenses.isEmpty
            ? const Center(child: Text('No expenses'))
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(expenses[index].expenseType),
                  subtitle: Text(CurrencyFormatter.format(expenses[index].amount)),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showExpenseEntrySheet(context);
          if (result != null) {
            final repo = ref.read(expenseRepositoryProvider);
            await repo.create(batchId, result as dynamic);
            ref.invalidate(batchExpensesProvider(batchId));
            ref.invalidate(batchPLProvider(batchId));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PackingTab extends ConsumerWidget {
  final String batchId;
  const _PackingTab({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Packing records'));
  }
}

class _SalesTab extends ConsumerWidget {
  final String batchId;
  const _SalesTab({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(batchSalesProvider(batchId));
    return Scaffold(
      body: salesAsync.when(
        data: (sales) => sales.isEmpty
            ? const Center(child: Text('No sales'))
            : ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Qty: ${sales[index].quantitySold}'),
                  subtitle: Text(CurrencyFormatter.format(sales[index].totalAmount)),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showSaleEntrySheet(context);
          if (result != null) {
            final repo = ref.read(saleRepositoryProvider);
            await repo.create(result as dynamic);
            ref.invalidate(batchSalesProvider(batchId));
            ref.invalidate(batchPLProvider(batchId));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PLTab extends ConsumerWidget {
  final String batchId;
  const _PLTab({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plAsync = ref.watch(batchPLProvider(batchId));
    return plAsync.when(
      data: (pl) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Batch P&L', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          _PLSection(title: 'Purchase Cost', amount: pl.costBreakdown.purchaseCost),
          _PLSection(title: 'Purchaser Daily Charges', amount: pl.costBreakdown.purchaserDailyCharges),
          _PLSection(title: 'Packing Cost', amount: pl.costBreakdown.packingCost),
          _PLSection(title: 'Transport Cost', amount: pl.costBreakdown.transportCost),
          _PLSection(title: 'Seller Expenses', amount: pl.costBreakdown.sellerExpenses),
          const Divider(thickness: 2),
          _PLSection(title: 'Total Cost', amount: pl.costBreakdown.totalCost, isTotal: true),
          const SizedBox(height: 16),
          _PLSection(title: 'Total Revenue', amount: pl.revenue.totalRevenue, color: Colors.green),
          _PLSection(title: 'Cash Received', amount: pl.revenue.cashReceived),
          _PLSection(title: 'Credit Outstanding', amount: pl.revenue.creditOutstanding, color: Colors.amber),
          const Divider(thickness: 2),
          _PLSection(
            title: 'Net Profit/Loss',
            amount: pl.netProfitLoss,
            isTotal: true,
            color: pl.netProfitLoss >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _PLSection extends StatelessWidget {
  final String title;
  final double amount;
  final bool isTotal;
  final Color? color;

  const _PLSection({required this.title, required this.amount, this.isTotal = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: color,
          )),
          AmountText(
            amount: amount,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
