import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';

class CustomerListPage extends ConsumerWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.id ?? '';
    final customersAsync = ref.watch(customerListProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/customers/new'),
        child: const Icon(Icons.add),
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No customers yet',
              actionLabel: 'Add Customer',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${customer.city ?? ''} · ${customer.shopName ?? ''}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(customer.outstandingBalance),
                        style: TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontWeight: FontWeight.w600,
                          color: customer.outstandingBalance > 0 ? Colors.amber.shade800 : Colors.green,
                          fontSize: 13,
                        ),
                      ),
                      if (customer.outstandingBalance > 0)
                        Text('due', style: TextStyle(fontSize: 10, color: Colors.amber.shade800)),
                    ],
                  ),
                  onTap: () => context.go('/customers/${customer.id}'),
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
