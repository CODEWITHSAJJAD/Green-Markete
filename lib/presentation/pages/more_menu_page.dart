import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'markets/market_list_page.dart';
import 'partners/partner_list_page.dart';
import 'products/product_list_page.dart';
import 'reports/reports_page.dart';
import 'settings/settings_page.dart';
import 'transactions/transaction_list_page.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    final items = <({IconData icon, String label, Widget page})>[
      (icon: Icons.category_outlined, label: 'Products', page: const ProductListPage()),
      (icon: Icons.group_outlined, label: 'Partners', page: const PartnerListPage()),
      (icon: Icons.storefront_outlined, label: 'Markets', page: const MarketListPage()),
      (icon: Icons.assessment_outlined, label: 'Reports', page: const ReportsPage()),
      (icon: Icons.swap_horiz_outlined, label: 'Transactions', page: const TransactionListPage()),
      (icon: Icons.settings_outlined, label: 'Settings', page: const SettingsPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              ),
              title: Text(user?.fullName ?? 'User'),
              subtitle: Text(user?.phone ?? user?.email ?? ''),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ),
          for (final item in items)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(item.icon, color: theme.colorScheme.primary),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => item.page),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
