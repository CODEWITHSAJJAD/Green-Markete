import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../l10n/app_localizations.dart';
import '../../pages/batches/batch_list_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/dashboard/dashboard_credit_alerts.dart';
import '../../widgets/dashboard/dashboard_hero_card.dart';
import '../../widgets/dashboard/dashboard_kpi_grid.dart';
import '../../widgets/dashboard/dashboard_quick_actions.dart';
import '../../widgets/recent_activity_list.dart';
import '../../widgets/section_header.dart';

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
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: provider.isLoading
            ? _buildShimmer(theme)
            : provider.error != null
            ? _buildError(theme, provider.error!, businessId)
            : RefreshIndicator(
                onRefresh: () =>
                    context.read<DashboardProvider>().load(businessId),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 20),
                    DashboardHeroCard(provider: provider),
                    const SizedBox(height: 12),
                    DashboardKpiGrid(provider: provider),
                    const SizedBox(height: 20),
                    const DashboardQuickActions(),
                    const SizedBox(height: 24),
                    const DashboardCreditAlerts(),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent batches',
                      trailing: 'View all',
                      onTapTrailing: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BatchListPage(),
                        ),
                      ),
                    ),
                    RecentActivityList(activities: provider.recentBatches),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
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
                firstName.isEmpty
                    ? l10n.dashboardGreetingFallback
                    : l10n.dashboardGreeting(firstName),
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

  Widget _buildError(ThemeData theme, String error, String businessId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MingCuteIcons.mgc_wifi_off_line,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('Could not load dashboard', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  context.read<DashboardProvider>().load(businessId),
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
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
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
