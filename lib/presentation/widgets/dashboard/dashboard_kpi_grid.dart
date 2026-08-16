import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../pages/batches/batch_list_page.dart';
import '../../pages/customers/customer_list_page.dart';
import '../../pages/products/product_list_page.dart';
import '../../pages/reports/reports_page.dart';
import '../../providers/dashboard_provider.dart';
import '../dashboard_card.dart';

/// Clean 2x2 Executive KPI Grid presenting core wholesale trading metrics with balanced symmetry.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 1. Customer Dues / Receivables
            Expanded(
              child: DashboardCard(
                title: 'Market Dues',
                value: CurrencyFormatter.format(provider.outstandingCredit),
                icon: HeroIcons.banknotes,
                color: AppColors.secondary,
                badge: provider.customersWithCreditCount > 0
                    ? '${provider.customersWithCreditCount} buyers'
                    : 'Settled',
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 2. Active Produce Batches
            Expanded(
              child: DashboardCard(
                title: 'Live Batches',
                value: '${provider.batchesCount} Batches',
                icon: HeroIcons.cube,
                color: AppColors.sky,
                badge: '${provider.activeBatchesCount} in Mandi',
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 3. Buyer Directory
            Expanded(
              child: DashboardCard(
                title: 'Buyer Directory',
                value: '${provider.customersCount} Clients',
                icon: HeroIcons.user_group,
                color: AppColors.indigo,
                badge: '${provider.customersWithCreditCount} with dues',
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
            const SizedBox(width: 12),
            // 4. Produce Varieties
            Expanded(
              child: DashboardCard(
                title: 'Produce Lines',
                value: '${provider.productsCount} Varieties',
                icon: HeroIcons.sparkles,
                color: AppColors.emerald,
                badge: 'Active catalog',
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ProductListPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
