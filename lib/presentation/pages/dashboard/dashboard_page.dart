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
  const DashboardPage({super.key, this.onMenu, this.onSelectTab});

  final VoidCallback? onMenu;
  final ValueChanged<int>? onSelectTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final businessId = auth.businessId ?? '';
      context.read<DashboardProvider>().load(businessId);
      context.read<ReportProvider>().loadOverdue(businessId);
      auth.loadBusinesses();
    });
  }

  void _showBusinessSwitcher(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.businesses.isEmpty) {
      auth.loadBusinesses();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentAuth = ctx.watch<AuthProvider>();
        final businesses = currentAuth.businesses;
        final theme = Theme.of(ctx);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Switch Business',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (businesses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No businesses found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: businesses.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final b = businesses[i];
                        final isCurrent = b.id == currentAuth.businessId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isCurrent
                                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              MingCuteIcons.mgc_store_2_line,
                              size: 20,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            b.name,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            b.businessType.replaceAll('_', ' '),
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: isCurrent
                              ? Icon(
                                  MingCuteIcons.mgc_check_circle_fill,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                )
                              : null,
                          onTap: () async {
                            Navigator.pop(ctx);
                            if (!isCurrent) {
                              await currentAuth.switchBusiness(b.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Switched to ${b.name}')),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
                    DashboardKpiGrid(
                      provider: provider,
                      onSelectTab: widget.onSelectTab,
                    ),
                    const SizedBox(height: 20),
                    const DashboardQuickActions(),
                    const SizedBox(height: 24),
                    const DashboardCreditAlerts(),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent batches',
                      trailing: 'View all',
                      onTapTrailing: () {
                        if (widget.onSelectTab != null) {
                          widget.onSelectTab!(1);
                        } else {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const BatchListPage(),
                            ),
                          );
                        }
                      },
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
    final businessName = auth.businesses
            .where((b) => b.id == auth.businessId)
            .map((b) => b.name)
            .firstOrNull ??
        'My Business';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MenuButton(onPressed: widget.onMenu),
            InkWell(
              onTap: () => _showBusinessSwitcher(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      MingCuteIcons.mgc_store_2_line,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      MingCuteIcons.mgc_down_line,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          firstName.isEmpty
              ? l10n.dashboardGreetingFallback
              : l10n.dashboardGreeting(firstName),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          DateFormat('EEEE, d MMMM').format(DateTime.now()),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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
