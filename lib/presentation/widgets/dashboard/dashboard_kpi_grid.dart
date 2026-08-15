import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../pages/batches/batch_list_page.dart';
import '../../pages/customers/customer_list_page.dart';
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
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Outstanding Credit',
                value: CurrencyFormatter.format(provider.outstandingCredit),
                icon: MingCuteIcons.mgc_wallet_3_line,
                color: AppColors.secondary,
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Customers',
                value: '${provider.customersCount}',
                icon: MingCuteIcons.mgc_user_3_line,
                color: const Color(0xFF8B5CF6),
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
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Total Batches',
                value: '${provider.batchesCount}',
                icon: MingCuteIcons.mgc_archive_line,
                color: const Color(0xFF0EA5E9),
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
            SizedBox(
              width: cardWidth,
              child: DashboardCard(
                title: 'Products',
                value: '${provider.productsCount}',
                icon: MingCuteIcons.mgc_package_line,
                color: const Color(0xFF10B981),
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
        );
      },
    );
  }
}
