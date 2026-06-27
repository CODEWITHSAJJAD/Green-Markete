import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/otp_verify_page.dart';
import '../../presentation/pages/auth/onboarding_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/batches/batch_list_page.dart';
import '../../presentation/pages/batches/batch_detail_page.dart';
import '../../presentation/pages/batches/batch_pl_page.dart';
import '../../presentation/pages/batches/create_batch_wizard.dart';
import '../../presentation/pages/products/product_list_page.dart';
import '../../presentation/pages/products/create_product_page.dart';
import '../../presentation/pages/sales/sales_list_page.dart';
import '../../presentation/pages/sales/quick_sale_page.dart';
import '../../presentation/pages/customers/customer_list_page.dart';
import '../../presentation/pages/customers/create_customer_page.dart';
import '../../presentation/pages/customers/customer_ledger_page.dart';
import '../../presentation/pages/customers/record_payment_page.dart';
import '../../presentation/pages/partners/partner_directory_page.dart';
import '../../presentation/pages/partners/create_partner_page.dart';
import '../../presentation/pages/partners/partner_profile_page.dart';
import '../../presentation/pages/markets/market_management_page.dart';
import '../../presentation/pages/reports/reports_hub_page.dart';
import '../../presentation/pages/reports/pl_report_page.dart';
import '../../presentation/pages/reports/credit_report_page.dart';
import '../../presentation/pages/transactions/partner_settlement_page.dart';
import '../../presentation/pages/transactions/partner_balance_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/settings/business_settings_page.dart';
import '../../presentation/pages/settings/access_management_page.dart';
import '../../presentation/pages/settings/profile_page.dart';
import '../../presentation/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isOnboarding = authState.needsOnboarding;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/verify-otp';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isOnboarding && !isOnboardingRoute) return '/onboarding';
      if (isLoggedIn && !isOnboarding && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const OTPVerifyPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/batches',
            builder: (context, state) => const BatchListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreateBatchWizard(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => BatchDetailPage(
                  batchId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'pl',
                    builder: (context, state) => BatchPLPage(
                      batchId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreateProductPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const QuickSalePage(),
              ),
            ],
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreateCustomerPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => CustomerLedgerPage(
                  customerId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'payment',
                    builder: (context, state) => RecordPaymentPage(
                      customerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/partners',
            builder: (context, state) => const PartnerDirectoryPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreatePartnerPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PartnerProfilePage(
                  partnerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/markets',
            builder: (context, state) => const MarketManagementPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsHubPage(),
            routes: [
              GoRoute(
                path: 'pl',
                builder: (context, state) => const PLReportPage(),
              ),
              GoRoute(
                path: 'credit',
                builder: (context, state) => const CreditReportPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const PartnerBalancePage(),
            routes: [
              GoRoute(
                path: 'settlement',
                builder: (context, state) => const PartnerSettlementPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'business',
                builder: (context, state) => const BusinessSettingsPage(),
              ),
              GoRoute(
                path: 'access',
                builder: (context, state) => const AccessManagementPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/batches')) return 1;
    if (location.startsWith('/sales')) return 2;
    if (location.startsWith('/customers')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(GoRouterState.of(context).matchedLocation),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/dashboard');
            case 1: context.go('/batches');
            case 2: context.go('/sales');
            case 3: context.go('/customers');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Batches'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
        ],
      ),
    );
  }
}
