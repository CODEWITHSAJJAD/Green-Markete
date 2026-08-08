import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'markets/market_list_page.dart';
import 'partners/partner_list_page.dart';
import 'products/product_list_page.dart';
import 'reports/reports_page.dart';
import 'settings/settings_page.dart';
import 'transactions/transaction_list_page.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    final items = <({IconData icon, String label, Widget page})>[
      (icon: MingCute.package_line, label: 'Products', page: const ProductListPage()),
      (icon: MingCute.user_4_line, label: 'Partners', page: const PartnerListPage()),
      (icon: MingCute.store_2_line, label: 'Markets', page: const MarketListPage()),
      (icon: MingCute.chart_bar_line, label: 'Reports', page: const ReportsPage()),
      (icon: MingCute.exchange_dollar_line, label: 'Transactions', page: const TransactionListPage()),
      (icon: MingCute.settings_3_line, label: 'Settings', page: const SettingsPage()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        leading: IconButton(
          icon: const Icon(MingCute.menu_line),
          onPressed: onMenu,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(MingCute.user_3_fill, color: theme.colorScheme.primary),
              ),
              title: Text(user?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(user?.phone ?? user?.email ?? ''),
              trailing: const Icon(MingCute.arrow_right_line),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 20, color: theme.colorScheme.primary),
                    ),
                    title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(
                      MingCute.arrow_right_line,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => item.page),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
