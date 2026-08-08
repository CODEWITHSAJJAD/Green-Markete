import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/green_card.dart';
import '../../widgets/recent_activity_list.dart';
import '../../widgets/section_header.dart';
import '../batches/batch_list_page.dart';
import '../batches/create_batch_wizard.dart';
import '../customers/customer_ledger_page.dart';
import '../customers/customer_list_page.dart';
import '../reports/overdue_customers_page.dart';
import '../reports/reports_page.dart';
import '../sales/quick_sale_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

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
              ? _buildError(theme, provider.error!, businessId)
              : RefreshIndicator(
                  onRefresh: () => context.read<DashboardProvider>().load(businessId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 20),
                      _buildHero(theme, provider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: 'Outstanding Credit',
                              value: CurrencyFormatter.format(provider.outstandingCredit),
                              icon: MingCuteIcons.mgc_wallet_3_line,
                              color: AppColors.secondary,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ReportsPage()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardCard(
                              title: 'Customers',
                              value: '${provider.customersCount}',
                              icon: MingCuteIcons.mgc_user_3_line,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CustomerListPage()),
                              ),
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
                              icon: MingCuteIcons.mgc_archive_line,
                              color: const Color(0xFF0EA5E9),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BatchListPage()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardCard(
                              title: 'Products',
                              value: '${provider.productsCount}',
                              icon: MingCuteIcons.mgc_package_line,
                              color: const Color(0xFF10B981),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BatchListPage()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _quickActionsRow(context),
                      const SizedBox(height: 24),
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
                                child: const Icon(MingCuteIcons.mgc_check_circle_line, size: 20, color: AppColors.success),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(MingCuteIcons.mgc_wallet_3_line, size: 20, color: AppColors.secondary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.fullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                        Text(c.city ?? '-', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(c.outstandingBalance),
                                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Recent batches',
                        trailing: 'View all',
                        onTapTrailing: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BatchListPage()),
                        ),
                      ),
                      RecentActivityList(activities: provider.recentBatches),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.user?.fullName ?? '').trim().split(' ').first;

    return Row(
      children: [
        _MenuButton(onPressed: widget.onMenu),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty ? 'Good to see you' : 'Good to see you, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(ThemeData theme, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s Revenue',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(MingCuteIcons.mgc_trending_up_line, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.activeBatchesCount} active',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            CurrencyFormatter.format(provider.todaySales),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gross sales recorded today across all batches',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsRow(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile(IconData icon, String label, VoidCallback onTap, Color color) {
      return GreenCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
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
            Expanded(child: tile(MingCuteIcons.mgc_add_line, 'New Batch', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateBatchWizard())), theme.colorScheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: tile(MingCuteIcons.mgc_bill_line, 'New Sale', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickSalePage())), theme.colorScheme.secondary)),
            const SizedBox(width: 8),
            Expanded(child: tile(MingCuteIcons.mgc_exchange_dollar_line, 'Record Payment', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerListPage())), Colors.deepPurple)),
            const SizedBox(width: 8),
            Expanded(child: tile(MingCuteIcons.mgc_chart_bar_line, 'Reports', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsPage())), const Color(0xFF0EA5E9))),
          ],
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme, String error, String businessId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MingCuteIcons.mgc_wifi_off_line, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Could not load dashboard', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.read<DashboardProvider>().load(businessId),
              icon: const Icon(MingCuteIcons.mgc_refresh_3_line, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _MenuButton(onPressed: widget.onMenu),
        const SizedBox(height: 20),
        Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerHighest,
          highlightColor: theme.colorScheme.surface,
          child: Column(
            children: [
              Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Container(height: 108, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 108, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(MingCuteIcons.mgc_menu_line, size: 22),
        ),
      ),
    );
  }
}
