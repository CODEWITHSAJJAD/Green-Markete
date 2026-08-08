import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
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
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
                  theme.colorScheme.secondary.withValues(alpha: 0.08),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance intelligence', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Monitor profitability, customer risk, and batch-level performance using your backend reports.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _navCard(context, theme, 'P&L Summary', MingCute.chart_bar_line, const PLReportPage()),
              _navCard(context, theme, 'Customer Credit', MingCute.wallet_3_line, const CreditReportPage()),
              _navCard(context, theme, 'Overdue Customers', MingCute.alert_line, const OverdueCustomersPage()),
              _navCard(context, theme, 'Market Performance', MingCute.store_2_line, const MarketPerformancePage()),
            ],
          ),
          const SizedBox(height: 24),
          _buildPLSection(theme, report),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Credit alerts'),
          const SizedBox(height: AppSpacing.sm),
          _buildOverdueSection(theme, report),
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
    final pl = report.plSummary;
    if (pl == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No data available.')),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metric(theme, 'Revenue', CurrencyFormatter.formatCompact(pl.totalRevenue), theme.colorScheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: _metric(theme, 'Cost', CurrencyFormatter.formatCompact(pl.totalCost), theme.colorScheme.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metric(theme, 'Profit / Loss', CurrencyFormatter.formatCompact(pl.totalProfitLoss), pl.totalProfitLoss >= 0 ? AppColors.profit : AppColors.error)),
            const SizedBox(width: 12),
            Expanded(child: _metric(theme, 'Batches', '${pl.totalBatches}', theme.colorScheme.tertiary)),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Recent batch summaries', style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        ...pl.batchSummaries.take(5).map(
          (batch) => GreenCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch.batchCode ?? 'Batch', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Revenue ${CurrencyFormatter.format(batch.revenue.totalRevenue)} • Cost ${CurrencyFormatter.format(batch.costBreakdown.totalCost)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(batch.netProfitLoss),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: batch.netProfitLoss >= 0 ? AppColors.profit : AppColors.error,
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
      return const Text('No overdue customer balances above the configured threshold.');
    }
    return Column(
      children: customers
          .map(
            (customer) => GreenCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.12),
                    child: Icon(MingCute.alert_line, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.fullName, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(customer.city ?? '-', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(customer.outstandingBalance),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _metric(ThemeData theme, String title, String value, Color color) {
    return GreenCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _navCard(BuildContext context, ThemeData theme, String title, IconData icon, Widget page) {
    return GreenCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
