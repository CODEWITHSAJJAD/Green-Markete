import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
import 'create_customer_page.dart';
import 'customer_ledger_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

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

  void _load(String businessId, String query) {
    context.read<CustomerProvider>().load(businessId, search: query.trim());
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
      customersSection = GreenCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(MingCute.wifi_off_line, size: 44, color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(provider.error!.toString(), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _load(businessId, _searchCtrl.text),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (provider.customers.isEmpty) {
      customersSection = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: EmptyState(
          icon: MingCute.user_3_line,
          title: 'No customers found',
          subtitle: _searchCtrl.text.trim().isEmpty
              ? 'Add your first customer to start tracking credit and payments.'
              : 'No results match your search.',
          actionLabel: _searchCtrl.text.trim().isEmpty ? 'New Customer' : null,
          onAction: _searchCtrl.text.trim().isEmpty ? _openCreateCustomer : null,
        ),
      );
    } else {
      customersSection = Column(
        children: provider.customers.map(
          (customer) {
            final tile = GreenCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      customer.fullName.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary),
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
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Icon(MingCute.delete_3_line, color: theme.colorScheme.error),
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
        leading: IconButton(
          icon: const Icon(MingCute.menu_line),
          onPressed: widget.onMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(MingCute.add_line),
            onPressed: _openCreateCustomer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.10),
                  AppColors.amberSurface.withValues(alpha: 0.6),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(MingCute.user_3_line, size: 26, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Credit & customers', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Track outstanding balances, open ledgers, and payment history without leaving the app.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (query) {
                    setState(() {});
                    _load(businessId, query);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name, phone, or shop',
                    prefixIcon: Icon(MingCute.search_2_line),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Customers'),
          const SizedBox(height: AppSpacing.sm),
          customersSection,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCustomer,
        icon: const Icon(MingCute.user_4_line),
        label: const Text('New Customer'),
      ),
    );
  }
}
