import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class RecentTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const RecentTransactions({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
              )
            else
              ...transactions.take(10).map((t) => ListTile(
                dense: true,
                leading: Icon(
                  t['type'] == 'sale' ? Icons.shopping_cart : t['type'] == 'payment' ? Icons.payments : Icons.receipt,
                  size: 20,
                  color: t['type'] == 'payment' ? Colors.green : Colors.amber,
                ),
                title: Text(t['description'] as String? ?? '', style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  t['date'] != null ? DateFormatter.timeAgo(DateTime.parse(t['date'] as String)) : '',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  CurrencyFormatter.format((t['amount'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
