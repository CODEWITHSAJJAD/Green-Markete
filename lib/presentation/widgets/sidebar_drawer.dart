import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../core/config/theme.dart';
import 'brand_logo.dart';

import '../pages/markets/market_list_page.dart';
import '../pages/partners/partner_list_page.dart';
import '../pages/products/product_list_page.dart';
import '../pages/reports/reports_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/suppliers/supplier_settlement_page.dart';
import '../pages/transactions/partner_dues_page.dart';
import '../pages/transactions/transaction_list_page.dart';
import '../pages/vehicles/vehicle_list_page.dart';
import '../providers/auth_provider.dart';

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
    final auth = context.watch<AuthProvider>();
    final caps = auth.capabilities;
    final canPurchaser = auth.canEditPurchaserSide;
    final canSeller = auth.canEditSellerSide;
    final isAccountant = caps.isAccountant;
    final isOwner = caps.isOwner;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(userName: userName, userSubtitle: userSubtitle),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  const _SectionHeader('Main'),
                  _NavTile(
                    icon: MingCuteIcons.mgc_home_5_line,
                    activeIcon: MingCuteIcons.mgc_home_5_fill,
                    label: 'Dashboard',
                    selected: currentTab == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  _NavTile(
                    icon: MingCuteIcons.mgc_shopping_bag_2_line,
                    activeIcon: MingCuteIcons.mgc_shopping_bag_2_fill,
                    label: 'Aamad Maal / Lots',
                    selected: currentTab == 1,
                    onTap: () => onSelectTab(1),
                  ),
                  if (isOwner || canSeller)
                    _NavTile(
                      icon: MingCuteIcons.mgc_bill_line,
                      activeIcon: MingCuteIcons.mgc_bill_fill,
                      label: 'Bikri & Boli',
                      selected: currentTab == 2,
                      onTap: () => onSelectTab(2),
                    ),
                  if (isOwner || canSeller || isAccountant)
                    _NavTile(
                      icon: MingCuteIcons.mgc_user_3_line,
                      activeIcon: MingCuteIcons.mgc_user_3_fill,
                      label: 'Khareedar Khata',
                      selected: currentTab == 3,
                      onTap: () => onSelectTab(3),
                    ),
                  const SizedBox(height: 8),
                  const _SectionHeader('Mandi Management'),
                  _NavTile(
                    icon: MingCuteIcons.mgc_package_line,
                    activeIcon: MingCuteIcons.mgc_package_fill,
                    label: 'Produce Catalog',
                    onTap: () => onOpenPage(const ProductListPage()),
                  ),
                  if (isOwner)
                    _NavTile(
                      icon: MingCuteIcons.mgc_user_4_line,
                      activeIcon: MingCuteIcons.mgc_user_4_fill,
                      label: 'Partners & Munshi',
                      onTap: () => onOpenPage(const PartnerListPage()),
                    ),
                  _NavTile(
                    icon: MingCuteIcons.mgc_store_2_line,
                    activeIcon: MingCuteIcons.mgc_store_2_fill,
                    label: 'Mandi Directory',
                    onTap: () => onOpenPage(const MarketListPage()),
                  ),
                  if (isOwner || canPurchaser)
                    _NavTile(
                      icon: MingCuteIcons.mgc_truck_line,
                      activeIcon: MingCuteIcons.mgc_truck_fill,
                      label: 'Transport & Vehicles',
                      onTap: () => onOpenPage(const VehicleListPage()),
                    ),
                  if (isOwner || canPurchaser || isAccountant)
                    _NavTile(
                      icon: MingCuteIcons.mgc_store_2_line,
                      activeIcon: MingCuteIcons.mgc_store_2_fill,
                      label: 'Zamindar Safaya',
                      onTap: () => onOpenPage(const SupplierSettlementPage()),
                    ),
                  const SizedBox(height: 8),
                  const _SectionHeader('Accounts & Insights'),
                  _NavTile(
                    icon: MingCuteIcons.mgc_chart_bar_line,
                    activeIcon: MingCuteIcons.mgc_chart_bar_fill,
                    label: 'P&L Reports',
                    onTap: () => onOpenPage(const ReportsPage()),
                  ),
                  if (isOwner || isAccountant || canSeller)
                    _NavTile(
                      icon: MingCuteIcons.mgc_exchange_dollar_line,
                      activeIcon: MingCuteIcons.mgc_exchange_dollar_fill,
                      label: 'Roznamcha Ledger',
                      onTap: () => onOpenPage(const TransactionListPage()),
                    ),
                  if (isOwner || canSeller || isAccountant)
                    _NavTile(
                      icon: MingCuteIcons.mgc_wallet_3_line,
                      activeIcon: MingCuteIcons.mgc_wallet_3_fill,
                      label: 'Partner Accounts',
                      onTap: () => onOpenPage(const PartnerDuesPage()),
                    ),
                  const SizedBox(height: 8),
                  const _SectionHeader('System'),
                  _NavTile(
                    icon: MingCuteIcons.mgc_settings_3_line,
                    activeIcon: MingCuteIcons.mgc_settings_3_fill,
                    label: 'Settings',
                    onTap: () => onOpenPage(const SettingsPage()),
                  ),
                  _NavTile(
                    icon: MingCuteIcons.mgc_exit_door_line,
                    activeIcon: MingCuteIcons.mgc_exit_door_fill,
                    label: 'Log out',
                    danger: true,
                    onTap: onLogout,
                  ),
                ],
              ),
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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandLogo(size: 38, isDarkBackground: true),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MandiRoznamcha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'منڈی کا ڈیجیٹل کھاتہ',
                    style: TextStyle(
                      color: AppColors.emerald,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
                    MingCuteIcons.mgc_arrow_right_line,
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
