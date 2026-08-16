import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/data_refresh.dart';
import '../providers/dashboard_provider.dart';
import '../providers/report_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/google_nav_bar.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sidebar_drawer.dart';
import 'batches/batch_list_page.dart';
import 'customers/customer_list_page.dart';
import 'dashboard/dashboard_page.dart';
import 'sales/sales_list_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<GlobalKey<NavigatorState>> _keys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void initState() {
    super.initState();
    DataRefreshNotifier.instance.addListener(_onSharedDataChanged);
  }

  @override
  void dispose() {
    DataRefreshNotifier.instance.removeListener(_onSharedDataChanged);
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  void _selectTab(int index) {
    _closeDrawer();
    _keys[index].currentState?.popUntil((route) => route.isFirst);
    setState(() => _index = index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadTabData(index));
  }

  /// Reloads the datasets shown by the given tab so the screens never show
  /// stale data after a change happened elsewhere.
  void _reloadTabData(int index) {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;
    switch (index) {
      case 0:
        context.read<DashboardProvider>().load(businessId);
        context.read<ReportProvider>().loadOverdue(businessId);
        break;
      case 1:
        context.read<BatchListProvider>().load(businessId);
        break;
      case 2:
        context.read<SellingBatchesProvider>().load(
          businessId,
          status: 'selling',
        );
        context.read<SaleProvider>().loadByBusiness(businessId);
        context.read<CustomerProvider>().load(businessId);
        break;
      case 3:
        context.read<CustomerProvider>().load(businessId);
        context.read<CustomerProvider>().loadShared(businessId);
        break;
    }
  }

  /// Fired from [DataRefreshNotifier] after any successful mutation: reloads
  /// every tab's dataset so the other screens using that data update too.
  void _onSharedDataChanged() {
    final businessId = DataRefreshNotifier.instance.lastBusinessId;
    if (businessId == null || businessId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < _pages.length; i++) {
        _reloadTabData(i);
      }
    });
  }

  Future<void> _openPage(Widget page) async {
    _closeDrawer();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    _reloadTabData(_index);
  }

  void _logout() {
    _closeDrawer();
    context.read<AuthProvider>().logout();
  }

  List<Widget> get _pages => [
        DashboardPage(onMenu: _openDrawer, onSelectTab: _selectTab),
        BatchListPage(onMenu: _openDrawer),
        SalesListPage(onMenu: _openDrawer),
        CustomerListPage(onMenu: _openDrawer),
      ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarDrawer(
        currentTab: _index,
        userName: user?.fullName,
        userSubtitle: user?.phone ?? user?.email,
        onSelectTab: _selectTab,
        onOpenPage: _openPage,
        onLogout: _logout,
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Navigator(key: _keys[i], onGenerateRoute: (_) => _routeFor(i)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: GoogleNavBar(
        currentIndex: _index,
        onTap: _selectTab,
        items: [
          GoogleNavItem(
            icon: MingCuteIcons.mgc_home_5_line,
            activeIcon: MingCuteIcons.mgc_home_5_fill,
            label: AppLocalizations.of(context)!.navHome,
          ),
          GoogleNavItem(
            icon: MingCuteIcons.mgc_shopping_bag_2_line,
            activeIcon: MingCuteIcons.mgc_shopping_bag_2_fill,
            label: AppLocalizations.of(context)!.navBatches,
          ),
          GoogleNavItem(
            icon: MingCuteIcons.mgc_bill_line,
            activeIcon: MingCuteIcons.mgc_bill_fill,
            label: AppLocalizations.of(context)!.navSales,
          ),
          GoogleNavItem(
            icon: MingCuteIcons.mgc_user_3_line,
            activeIcon: MingCuteIcons.mgc_user_3_fill,
            label: AppLocalizations.of(context)!.navCustomers,
          ),
        ],
      ),
    );
  }

  Route<dynamic> _routeFor(int index) {
    return MaterialPageRoute(builder: (_) => _pages[index]);
  }
}
