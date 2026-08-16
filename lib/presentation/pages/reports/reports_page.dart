import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
import 'credit_report_page.dart';
import 'market_performance_page.dart';
import 'overdue_customers_page.dart';
import 'pl_report_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    final report = context.read<ReportProvider>();
    report.loadPLSummary(businessId);
    report.loadOverdue(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = context.watch<ReportProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Financial & Performance Reports',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(
                    HeroIcons.presentation_chart_line,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Executive Intelligence',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'P&L summaries, Customer risk audits, and wholesale channel benchmarks.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              _navCard(
                context,
                'P&L Statement',
                HeroIcons.chart_bar_square,
                AppColors.emerald,
                const PLReportPage(),
              ),
              _navCard(
                context,
                'Customer Balances',
                HeroIcons.banknotes,
                AppColors.amber,
                const CreditReportPage(),
              ),
              _navCard(
                context,
                'Overdue Dues',
                HeroIcons.exclamation_triangle,
                AppColors.rose,
                const OverdueCustomersPage(),
              ),
              _navCard(
                context,
                'Market Channels',
                HeroIcons.building_storefront,
                AppColors.indigo,
                const MarketPerformancePage(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPLSection(theme, report),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Critical Receivables Alerts'),
          const SizedBox(height: 8),
          _buildOverdueSection(theme, report),
        ],
      ),
    );
  }

  Widget _navCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return GreenCard(
      padding: const EdgeInsets.all(14),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(HeroIcons.arrow_up_right, size: 14, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPLSection(ThemeData theme, ReportProvider report) {
    if (report.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
            const SizedBox(height: 10),
            Text(report.error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (report.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final pl = report.plSummary;
    if (pl == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No report data available')),
      );
    }
    final isProfit = pl.totalProfitLoss >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Business Summary Metrics'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metric(
                'Total Revenue',
                CurrencyFormatter.format(pl.totalRevenue),
                AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metric(
                'Total Expenses',
                CurrencyFormatter.format(pl.totalCost),
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metric(
                'Net Profit / Loss',
                CurrencyFormatter.format(pl.totalProfitLoss),
                isProfit ? AppColors.emerald : AppColors.rose,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metric(
                'Batches Analyzed',
                '${pl.totalBatches} Batches',
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Batch Performance Breakdown'),
        const SizedBox(height: 10),
        ...pl.batchSummaries
            .take(5)
            .map(
              (batch) => GreenCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${batch.batchCode ?? 'Batch'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Revenue ${CurrencyFormatter.format(batch.revenue.totalRevenue)} • Cost ${CurrencyFormatter.format(batch.costBreakdown.totalCost)}',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(batch.netProfitLoss),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: batch.netProfitLoss >= 0
                            ? AppColors.emerald
                            : AppColors.rose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildOverdueSection(ThemeData theme, ReportProvider report) {
    if (report.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(report.error!),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (report.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final customers = report.overdue;
    if (customers.isEmpty) {
      return GreenCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              HeroIcons.check_circle,
              color: AppColors.emerald,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No overdue customer balances detected.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: customers
          .map(
            (customer) => GreenCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.roseSurface,
                    child: const Icon(
                      HeroIcons.exclamation_triangle,
                      color: AppColors.rose,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                            overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.city ?? 'Local Market',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        CurrencyFormatter.format(customer.outstandingBalance),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _metric(String title, String value, Color color) {
    return GreenCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
