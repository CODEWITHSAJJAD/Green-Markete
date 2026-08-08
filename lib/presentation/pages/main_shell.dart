import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/google_nav_bar.dart';
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

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  void _selectTab(int index) {
    _closeDrawer();
    setState(() => _index = index);
  }

  void _openPage(Widget page) {
    _closeDrawer();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _logout() {
    _closeDrawer();
    context.read<AuthProvider>().logout();
  }

  List<Widget> get _pages => [
        DashboardPage(onMenu: _openDrawer),
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
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _pages.length; i++)
            Navigator(key: _keys[i], onGenerateRoute: (_) => _routeFor(i)),
        ],
      ),
      bottomNavigationBar: GoogleNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          GoogleNavItem(
            icon: MingCuteIcons.mgc_home_5_line,
            activeIcon: MingCuteIcons.mgc_home_5_fill,
            label: 'Home',
          ),
          GoogleNavItem(
            icon: MingCuteIcons.mgc_shopping_bag_2_line,
            activeIcon: MingCuteIcons.mgc_shopping_bag_2_fill,
            label: 'Batches',
          ),
          GoogleNavItem(
            icon: MingCuteIcons.mgc_bill_line,
            activeIcon: MingCuteIcons.mgc_bill_fill,
            label: 'Sales',
          ),
          GoogleNavItem(
            icon: MingCuteIcons.mgc_user_3_line,
            activeIcon: MingCuteIcons.mgc_user_3_fill,
            label: 'Customers',
          ),
        ],
      ),
    );
  }

  Route<dynamic> _routeFor(int index) {
    return MaterialPageRoute(builder: (_) => _pages[index]);
  }
}
