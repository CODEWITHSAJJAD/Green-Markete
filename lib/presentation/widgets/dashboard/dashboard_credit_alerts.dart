import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../pages/customers/customer_ledger_page.dart';
import '../../pages/reports/overdue_customers_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../green_card.dart';
import '../section_header.dart';

class DashboardCreditAlerts extends StatelessWidget {
  const DashboardCreditAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = context.watch<ReportProvider>();
    final businessId = context.watch<AuthProvider>().businessId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Credit alerts',
          trailing: 'View all',
          onTapTrailing: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OverdueCustomersPage()),
          ),
        ),
        if (report.isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          )
        else if (report.error != null)
          Text(report.error!, style: theme.textTheme.bodySmall)
        else if (report.overdue.isEmpty)
          GreenCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    MingCuteIcons.mgc_check_circle_line,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Text('No overdue customers.', style: theme.textTheme.bodyMedium),
              ],
            ),
          )
        else
          Column(
            children: report.overdue.take(3).map((c) {
              return GreenCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                onTap: () {
                  final cust = CustomerModel(
                    id: c.id,
                    businessId: businessId,
                    fullName: c.fullName,
                    phone: c.phone,
                    city: c.city,
                    outstandingBalance: c.outstandingBalance,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerLedgerPage(customer: cust),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        MingCuteIcons.mgc_wallet_3_line,
                        size: 20,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.fullName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(c.city ?? '-', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(c.outstandingBalance),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
