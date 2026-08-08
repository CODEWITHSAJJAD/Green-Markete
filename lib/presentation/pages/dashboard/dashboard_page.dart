import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/recent_activity_list.dart';
import '../batches/batch_list_page.dart';
import '../batches/create_batch_wizard.dart';
import '../customers/customer_ledger_page.dart';
import '../customers/customer_list_page.dart';
import '../reports/overdue_customers_page.dart';
import '../reports/reports_page.dart';
import '../sales/quick_sale_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<AuthProvider>().businessId ?? '';
      context.read<DashboardProvider>().load(businessId);
      context.read<ReportProvider>().loadOverdue(businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final report = context.watch<ReportProvider>();
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';

    return Scaffold(
      body: provider.isLoading
          ? _buildShimmer(theme)
          : provider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('Could not load dashboard', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(provider.error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => context.read<DashboardProvider>().load(businessId),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<DashboardProvider>().load(businessId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      Text('Dashboard', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text('Today\'s overview', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: 'Today\'s Revenue',
                              value: CurrencyFormatter.format(provider.todaySales),
                              icon: Icons.trending_up_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardCard(
                              title: 'Active Batches',
                              value: '${provider.activeBatchesCount}',
                              icon: Icons.inventory_2_rounded,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: 'Outstanding Credit',
                              value: CurrencyFormatter.format(provider.outstandingCredit),
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardCard(
                              title: 'Customers',
                              value: '${provider.customersCount}',
                              icon: Icons.people_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: 'Total Batches',
                              value: '${provider.batchesCount}',
                              icon: Icons.layers_rounded,
                              color: const Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardCard(
                              title: 'Products',
                              value: '${provider.productsCount}',
                              icon: Icons.category_rounded,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _quickActionsRow(context),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Credit alerts', style: theme.textTheme.titleLarge),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OverdueCustomersPage()),
                            ),
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (report.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        )
                      else if (report.error != null)
                        Text(report.error!)
                      else if (report.overdue.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('No overdue customers.', style: theme.textTheme.bodySmall),
                        )
                      else
                        Column(
                          children: report.overdue.take(3).map((c) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                  child: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.secondary),
                                ),
                                title: Text(c.fullName),
                                subtitle: Text(c.city ?? '-'),
                                trailing: Text(
                                  CurrencyFormatter.format(c.outstandingBalance),
                                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
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
                                    MaterialPageRoute(builder: (_) => CustomerLedgerPage(customer: cust)),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent batches', style: theme.textTheme.titleLarge),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BatchListPage()),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RecentActivityList(activities: provider.recentBatches),
                    ],
                  ),
                ),
    );
  }

  Widget _quickActionsRow(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile(IconData icon, String label, VoidCallback onTap, Color color) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: tile(Icons.add_box_rounded, 'New Batch', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateBatchWizard())), theme.colorScheme.primary)),
        const SizedBox(width: 8),
        Expanded(child: tile(Icons.point_of_sale_rounded, 'New Sale', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickSalePage())), theme.colorScheme.secondary)),
        const SizedBox(width: 8),
        Expanded(child: tile(Icons.payments_outlined, 'Record Payment', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerListPage())), Colors.deepPurple)),
        const SizedBox(width: 8),
        Expanded(child: tile(Icons.bar_chart_rounded, 'Reports', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsPage())), const Color(0xFF0EA5E9))),
      ],
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('Dashboard', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 24),
        Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest,
          highlightColor: theme.colorScheme.surface,
          child: Column(
            children: [
              Row(children: [
                Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
