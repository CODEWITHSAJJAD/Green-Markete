import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({
    super.key,
    required this.currentTab,
    required this.userName,
    required this.userSubtitle,
    required this.onSelectTab,
    required this.onOpenPage,
    required this.onLogout,
  });

  final int currentTab;
  final String? userName;
  final String? userSubtitle;
  final ValueChanged<int> onSelectTab;
  final void Function(Widget page) onOpenPage;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(userName: userName, userSubtitle: userSubtitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: [
                const _SectionHeader('Main'),
                _NavTile(
                  icon: MingCute.home_5_line,
                  activeIcon: MingCute.home_5_fill,
                  label: 'Dashboard',
                  selected: currentTab == 0,
                  onTap: () => onSelectTab(0),
                ),
                _NavTile(
                  icon: MingCute.shopping_bag_2_line,
                  activeIcon: MingCute.shopping_bag_2_fill,
                  label: 'Batches',
                  selected: currentTab == 1,
                  onTap: () => onSelectTab(1),
                ),
                _NavTile(
                  icon: MingCute.bill_line,
                  activeIcon: MingCute.bill_fill,
                  label: 'Sales',
                  selected: currentTab == 2,
                  onTap: () => onSelectTab(2),
                ),
                _NavTile(
                  icon: MingCute.user_3_line,
                  activeIcon: MingCute.user_3_fill,
                  label: 'Customers',
                  selected: currentTab == 3,
                  onTap: () => onSelectTab(3),
                ),
                const SizedBox(height: 8),
                const _SectionHeader('Manage'),
                _NavTile(
                  icon: MingCute.package_line,
                  activeIcon: MingCute.package_fill,
                  label: 'Products',
                  onTap: () => onOpenPage(const PlaceholderPage(label: 'Products')),
                ),
                _NavTile(
                  icon: MingCute.user_4_line,
                  activeIcon: MingCute.user_4_fill,
                  label: 'Partners',
                  onTap: () => onOpenPage(const PlaceholderPage(label: 'Partners')),
                ),
                _NavTile(
                  icon: MingCute.store_2_line,
                  activeIcon: MingCute.store_2_fill,
                  label: 'Markets',
                  onTap: () => onOpenPage(const PlaceholderPage(label: 'Markets')),
                ),
                const SizedBox(height: 8),
                const _SectionHeader('Insights'),
                _NavTile(
                  icon: MingCute.chart_bar_line,
                  activeIcon: MingCute.chart_bar_fill,
                  label: 'Reports',
                  onTap: () => onOpenPage(const PlaceholderPage(label: 'Reports')),
                ),
                _NavTile(
                  icon: MingCute.exchange_dollar_line,
                  activeIcon: MingCute.exchange_dollar_fill,
                  label: 'Transactions',
                  onTap: () => onOpenPage(const PlaceholderPage(label: 'Transactions')),
                ),
                const SizedBox(height: 8),
                const _SectionHeader('Account'),
                _NavTile(
                  icon: MingCute.settings_3_line,
                  activeIcon: MingCute.settings_3_fill,
                  label: 'Settings',
                  onTap: () => onOpenPage(const PlaceholderPage(label: 'Settings')),
                ),
                _NavTile(
                  icon: MingCute.exit_door_line,
                  activeIcon: MingCute.exit_door_fill,
                  label: 'Log out',
                  danger: true,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.userName, this.userSubtitle});

  final String? userName;
  final String? userSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 24,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(MingCute.leaf_2_fill, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Green Market',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Wholesale Management',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  _initials(userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? 'Guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (userSubtitle != null && userSubtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        userSubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    final Color bg;
    if (danger) {
      color = scheme.error;
      bg = scheme.error.withValues(alpha: 0.08);
    } else if (selected) {
      color = scheme.primary;
      bg = scheme.primary.withValues(alpha: 0.10);
    } else {
      color = scheme.onSurfaceVariant;
      bg = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(selected || danger ? activeIcon : icon, size: 22, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (!selected && !danger)
                  Icon(
                    MingCute.arrow_right_line,
                    size: 18,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MingCute.information_line, size: 44, color: scheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              '$label coming soon',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
