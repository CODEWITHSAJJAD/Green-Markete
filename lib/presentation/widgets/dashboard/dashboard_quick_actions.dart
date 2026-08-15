import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../pages/batches/create_batch_wizard.dart';
import '../../pages/customers/customer_list_page.dart';
import '../../pages/reports/reports_page.dart';
import '../../pages/sales/quick_sale_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capability.dart';
import '../green_card.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.capabilities.can(Capability.createBatch);
    final canSell = auth.canEditSellerSide;

    Widget tile(IconData icon, String label, VoidCallback onTap, Color color) {
      return GreenCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            if (canCreate)
              Expanded(
                child: tile(
                  MingCuteIcons.mgc_add_line,
                  'New Batch',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateBatchWizard(),
                    ),
                  ),
                  theme.colorScheme.primary,
                ),
              ),
            if (canSell) ...[
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  MingCuteIcons.mgc_bill_line,
                  'New Sale',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QuickSalePage(),
                    ),
                  ),
                  theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  MingCuteIcons.mgc_exchange_dollar_line,
                  'Record Payment',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerListPage(),
                    ),
                  ),
                  Colors.deepPurple,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: tile(
                MingCuteIcons.mgc_chart_bar_line,
                'Reports',
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
                const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
