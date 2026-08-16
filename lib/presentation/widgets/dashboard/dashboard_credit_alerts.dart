import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          title: 'Credit & Dues Monitor',
          trailing: 'View All',
          onTapTrailing: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OverdueCustomersPage()),
          ),
        ),
        const SizedBox(height: 4),
        if (report.isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          )
        else if (report.error != null)
          Text(report.error!, style: theme.textTheme.bodySmall)
        else if (report.overdue.isEmpty)
          GreenCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    HeroIcons.check_circle,
                    size: 20,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Receivables In Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No Customers have overdue credit balances',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        color: AppColors.amberSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        HeroIcons.exclamation_triangle,
                        size: 20,
                        color: AppColors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (c.city != null && c.city!.isNotEmpty) c.city,
                              'Dues pending',
                            ].join(' • '),
                            style: GoogleFonts.inter(
                              color: AppColors.rose,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(c.outstandingBalance),
                          style: GoogleFonts.inter(
                            color: AppColors.rose,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open Ledger',
                              style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              HeroIcons.chevron_right,
                              size: 11,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ],
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
