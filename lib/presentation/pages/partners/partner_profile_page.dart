import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class PartnerProfilePage extends ConsumerWidget {
  final String partnerId;
  const PartnerProfilePage({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(partnerLedgerProvider(partnerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Profile')),
      body: ledgerAsync.when(
        data: (ledger) {
          final entries = ledger['entries'] as List<dynamic>? ?? [];
          final balance = ledger['balance'] as Map<String, dynamic>? ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(Icons.person, size: 32, color: Colors.green),
                      ),
                      const SizedBox(height: 12),
                      const Text('Partner Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Partner Role', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Chip(
                        label: const Text('Viewer'),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Divider(),
                      ListTile(
                        title: const Text('Total Sent'),
                        trailing: Text(CurrencyFormatter.format((balance['total_sent'] as num?)?.toDouble() ?? 0)),
                      ),
                      ListTile(
                        title: const Text('Total Received'),
                        trailing: Text(CurrencyFormatter.format((balance['total_received'] as num?)?.toDouble() ?? 0)),
                      ),
                      ListTile(
                        title: const Text('Net Balance'),
                        trailing: Text(
                          CurrencyFormatter.format((balance['net_balance'] as num?)?.toDouble() ?? 0),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ((balance['net_balance'] as num?)?.toDouble() ?? 0) >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w600)),
                ...entries.map((e) => ListTile(
                  dense: true,
                  title: Text(e['description'] as String? ?? ''),
                  subtitle: Text(e['date'] as String? ?? ''),
                  trailing: Text(CurrencyFormatter.format((e['amount'] as num?)?.toDouble() ?? 0)),
                )),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
