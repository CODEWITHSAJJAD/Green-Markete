import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/config/theme.dart';
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Switch Business Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(HeroIcons.x_mark, size: 20),
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
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: businesses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final b = businesses[i];
                        final isSelected = b.id == currentAuth.businessId;

                        return InkWell(
                          onTap: () async {
                            Navigator.pop(ctx);
                            if (isSelected) return;
                            await currentAuth.switchBusiness(b.id);
                            if (context.mounted) {
                              context.read<DashboardProvider>().load(b.id);
                              context.read<ReportProvider>().loadOverdue(b.id);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primarySurface
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    HeroIcons.building_storefront,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        b.businessType == 'single' ? 'Solo Business' : 'Multi-Partner Enterprise',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    HeroIcons.check_circle,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
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
    final theme = Theme.of(context);
    final provider = context.watch<DashboardProvider>();
    final businessId = context.watch<AuthProvider>().businessId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: provider.isLoading && provider.batchesCount == 0
            ? _buildShimmer(theme)
            : provider.error != null && provider.batchesCount == 0
            ? _buildError(theme, provider.error!, businessId)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    context.read<DashboardProvider>().load(businessId),
                    context.read<ReportProvider>().loadOverdue(businessId),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 18),
                    DashboardHeroCard(provider: provider),
                    const SizedBox(height: 18),
                    DashboardKpiGrid(
                      provider: provider,
                      onSelectTab: widget.onSelectTab,
                    ),
                    const SizedBox(height: 22),
                    const DashboardQuickActions(),
                    const SizedBox(height: 22),
                    const DashboardCreditAlerts(),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Recent Batches',
                      trailing: 'View All',
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
                    const SizedBox(height: 6),
                    RecentActivityList(activities: provider.recentBatches),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.user?.fullName ?? '').trim().split(' ').first;
    final businessName =
        auth.businesses
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      HeroIcons.building_storefront,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(HeroIcons.chevron_down, size: 13, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _timeGreeting(firstName),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _timeGreeting(String firstName) {
    final hour = DateTime.now().hour;
    final timeStr = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return firstName.isNotEmpty ? '$timeStr, $firstName 👋' : '$timeStr 👋';
  }

  Widget _buildError(ThemeData theme, String error, String businessId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HeroIcons.wifi,
              size: 56,
              color: AppColors.rose.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  context.read<DashboardProvider>().load(businessId),
              icon: const Icon(HeroIcons.arrow_path, size: 18),
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
          baseColor: AppColors.surfaceAlt,
          highlightColor: AppColors.surface,
          child: Column(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(HeroIcons.bars_3_bottom_left, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
