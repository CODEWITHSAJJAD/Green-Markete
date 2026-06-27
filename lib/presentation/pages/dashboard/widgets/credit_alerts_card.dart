import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/report_model.dart';
import '../../../../core/utils/currency_formatter.dart';

class CreditAlertsCard extends StatelessWidget {
  final List<CreditReportModel> overdueCustomers;

  const CreditAlertsCard({super.key, required this.overdueCustomers});

  @override
  Widget build(BuildContext context) {
    if (overdueCustomers.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                const Text('Credit Alerts', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ...overdueCustomers.take(3).map((c) => ListTile(
              dense: true,
              title: Text(c.fullName),
              trailing: Text(
                CurrencyFormatter.format(c.outstandingBalance),
                style: TextStyle(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto Mono',
                ),
              ),
              onTap: () => context.go('/customers/${c.id}'),
            )),
          ],
        ),
      ),
    );
  }
}
