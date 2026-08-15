import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

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
            // 1. Customer Credit / Receivables
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Customer Credit',
                value: CurrencyFormatter.format(provider.outstandingCredit),
                icon: MingCuteIcons.mgc_wallet_3_line,
                color: AppColors.secondary,
                badge: provider.customersWithCreditCount > 0
                    ? '${provider.customersWithCreditCount} due'
                    : 'All clear',
                subtitle: 'Receivables from buyers',
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
              ),
            ),

            // 2. Batches in Progress & Selling
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Batches Pipeline',
                value: '${provider.batchesCount}',
                icon: MingCuteIcons.mgc_shopping_bag_2_line,
                color: const Color(0xFF0EA5E9),
                badge: '${provider.activeBatchesCount} active',
                subtitle: '${provider.sellingBatchesCount} ready to sell',
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

            // 3. Customers & Buyers
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Total Customers',
                value: '${provider.customersCount}',
                icon: MingCuteIcons.mgc_user_3_line,
                color: const Color(0xFF8B5CF6),
                badge: '${provider.customersWithCreditCount} with credit',
                subtitle: 'Buyers & market clients',
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

            // 4. Products Catalog
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Product Catalog',
                value: '${provider.productsCount}',
                icon: MingCuteIcons.mgc_leaf_2_line,
                color: const Color(0xFF10B981),
                badge: 'Active lines',
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
