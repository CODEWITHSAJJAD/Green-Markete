import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/credit_indicator.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class CustomerLedgerPage extends ConsumerWidget {
  final String customerId;
  const CustomerLedgerPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(customerLedgerProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Ledger')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/$customerId/payment'),
        icon: const Icon(Icons.payments),
        label: const Text('Record Payment'),
      ),
      body: ledgerAsync.when(
        data: (entries) {
          final totalPurchased = entries.fold<double>(0, (sum, e) => e.type == 'sale' ? sum + e.amount : sum);
          final totalPaid = entries.fold<double>(0, (sum, e) => e.type == 'payment' ? sum + (-e.amount) : sum);
          final balance = totalPurchased - totalPaid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Customer Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(label: 'Total Purchased', amount: totalPurchased),
                          _Stat(label: 'Total Paid', amount: totalPaid, color: Colors.green),
                          _Stat(label: 'Balance', amount: balance, color: balance > 0 ? Colors.amber : Colors.green),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CreditIndicator(totalPurchased: totalPurchased, totalPaid: totalPaid),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...entries.map((entry) => ListTile(
                dense: true,
                leading: Icon(
                  entry.type == 'payment' ? Icons.payments : Icons.shopping_cart,
                  size: 20,
                  color: entry.type == 'payment' ? Colors.green : Colors.amber,
                ),
                title: Text(entry.description, style: const TextStyle(fontSize: 13)),
                subtitle: Text(entry.date, style: const TextStyle(fontSize: 11)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(amount: entry.amount, fontSize: 13),
                    Text(
                      'Bal: ${CurrencyFormatter.format(entry.runningBalance)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _Stat({required this.label, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        AmountText(amount: amount, fontSize: 16, color: color),
      ],
    );
  }
}
