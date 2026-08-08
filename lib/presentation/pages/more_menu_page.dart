import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../core/config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/green_card.dart';
import '../widgets/section_header.dart';
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          GreenCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(MingCute.user_3_fill, color: AppColors.primary),
              ),
              title: Text(user?.fullName ?? 'User', style: theme.textTheme.titleMedium),
              subtitle: Text(user?.phone ?? user?.email ?? ''),
              trailing: Icon(MingCute.arrow_right_line, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Workspace'),
          const SizedBox(height: AppSpacing.sm),
          GreenCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 52, color: AppColors.divider.withValues(alpha: 0.7)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(item.icon, size: 20, color: AppColors.primary),
                    ),
                    title: Text(item.label, style: theme.textTheme.titleSmall),
                    trailing: Icon(MingCute.arrow_right_line, size: 18, color: AppColors.textTertiary),
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
