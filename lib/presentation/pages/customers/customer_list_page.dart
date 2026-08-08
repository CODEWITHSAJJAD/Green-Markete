import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/confirm_dialog.dart';
import 'create_customer_page.dart';
import 'customer_ledger_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<AuthProvider>().businessId ?? '';
      context.read<CustomerProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreateCustomer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCustomerPage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<CustomerProvider>().load(businessId, search: _searchCtrl.text.trim());
  }

  Future<void> _deleteCustomer(String customerId) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export available in a later build')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId ?? '';
    final isOwner = auth.user?.role == 'owner';
    final provider = context.watch<CustomerProvider>();

    Widget customersSection;
    if (provider.isLoading) {
      customersSection = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (provider.error != null) {
      customersSection = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(provider.error!.toString()),
      );
    } else if (provider.customers.isEmpty) {
      customersSection = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 52, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No customers found', style: theme.textTheme.titleLarge),
          ],
        ),
      );
    } else {
      customersSection = Column(
        children: provider.customers.map(
          (customer) {
            final tile = Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      customer.fullName.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.fullName, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          [customer.shopName, customer.city]
                              .where((item) => item != null && item.isNotEmpty)
                              .join('  •  '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(customer.outstandingBalance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: customer.outstandingBalance > 0
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Outstanding', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            );
            if (!isOwner) {
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CustomerLedgerPage(customer: customer)),
                ),
                child: tile,
              );
            }
            return Dismissible(
              key: ValueKey(customer.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              ),
              confirmDismiss: (_) => showConfirmDialog(
                context,
                title: 'Delete customer?',
                message: 'This will hide the customer from all views. Data is retained for audit.',
                confirmLabel: 'Delete',
                isDestructive: true,
              ),
              onDismissed: (_) => _deleteCustomer(customer.id),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CustomerLedgerPage(customer: customer)),
                ),
                child: tile,
              ),
            );
          },
        ).toList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _openCreateCustomer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
                  theme.colorScheme.secondary.withValues(alpha: 0.07),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credit & customer relationships', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Track outstanding balances, open ledgers, and payment history without leaving the app.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (query) {
                    setState(() {});
                    context.read<CustomerProvider>().load(businessId, search: query.trim());
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name, phone, or shop',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          customersSection,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCustomer,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New Customer'),
      ),
    );
  }
}
