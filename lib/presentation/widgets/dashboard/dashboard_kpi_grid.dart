import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../pages/batches/batch_list_page.dart';
import '../../pages/customers/customer_list_page.dart';
import '../../pages/products/product_list_page.dart';
import '../../pages/reports/reports_page.dart';
import '../../providers/dashboard_provider.dart';
import '../dashboard_card.dart';

class DashboardKpiGrid extends StatelessWidget {
  final DashboardProvider provider;
  final ValueChanged<int>? onSelectTab;

  const DashboardKpiGrid({
    super.key,
    required this.provider,
    this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final factor = formFactorOf(ctx);
        final cardWidth = switch (factor) {
          FormFactor.compact => (constraints.maxWidth - 12) / 2,
          FormFactor.medium => (constraints.maxWidth - 24) / 3,
          FormFactor.expanded => (constraints.maxWidth - 36) / 4,
        };

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 1. Customer Dues / Receivables
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Customer Dues',
                value: CurrencyFormatter.format(provider.outstandingCredit),
                icon: HeroIcons.banknotes,
                color: AppColors.secondary,
                badge: provider.customersWithCreditCount > 0
                    ? '${provider.customersWithCreditCount} pending'
                    : 'All settled',
                subtitle: 'Receivables from buyers',
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
              ),
            ),

            // 2. Active Produce Batches
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Produce Batches',
                value: '${provider.batchesCount} Batches',
                icon: HeroIcons.cube,
                color: AppColors.sky,
                badge: '${provider.activeBatchesCount} in pipeline',
                subtitle: '${provider.sellingBatchesCount} selling in market',
                onTap: () {
                  if (onSelectTab != null) {
                    onSelectTab!(1);
                  } else {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const BatchListPage()),
                    );
                  }
                },
              ),
            ),

            // 3. Buyer Directory
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Buyer Directory',
                value: '${provider.customersCount} Clients',
                icon: HeroIcons.user_group,
                color: AppColors.indigo,
                badge: '${provider.customersWithCreditCount} with dues',
                subtitle: 'Registered shopkeepers',
                onTap: () {
                  if (onSelectTab != null) {
                    onSelectTab!(3);
                  } else {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const CustomerListPage()),
                    );
                  }
                },
              ),
            ),

            // 4. Produce Varieties
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Produce Lines',
                value: '${provider.productsCount} Varieties',
                icon: HeroIcons.sparkles,
                color: AppColors.emerald,
                badge: 'Active catalog',
                subtitle: 'Produce lines & units',
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ProductListPage()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
