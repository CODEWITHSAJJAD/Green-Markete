import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class CreditReportPage extends ConsumerWidget {
  const CreditReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final creditAsync = ref.watch(creditReportProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Credit')),
      body: creditAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No outstanding credit'));
          }
          final sorted = List.from(customers)..sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final c = sorted[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    child: Icon(Icons.person, color: Colors.amber.shade700),
                  ),
                  title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c.city ?? ''),
                  trailing: Text(
                    CurrencyFormatter.format(c.outstandingBalance),
                    style: TextStyle(
                      fontFamily: 'Roboto Mono',
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () => context.go('/customers/${c.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
