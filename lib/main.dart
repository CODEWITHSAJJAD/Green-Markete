import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/theme.dart';
import 'core/supabase/supabase_service.dart';
import 'presentation/pages/auth/auth_navigator.dart';
import 'presentation/pages/auth/onboarding_page.dart';
import 'presentation/pages/auth/splash_page.dart';
import 'presentation/pages/main_shell.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/batch_provider.dart';
import 'presentation/providers/batch_wizard_provider.dart';
import 'presentation/providers/business_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/customer_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/market_provider.dart';
import 'presentation/providers/partner_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/report_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/batch_repository.dart';
import 'data/repositories/business_repository.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/partner_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/sale_repository.dart';
import 'data/repositories/transaction_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository())),
        ChangeNotifierProvider(create: (_) => BusinessProvider(BusinessRepository())),
        ChangeNotifierProvider(create: (_) => DashboardProvider(DashboardRepository())),
        ChangeNotifierProvider(create: (_) => BatchListProvider(BatchRepository())),
        ChangeNotifierProvider(create: (_) => BatchDetailProvider(BatchRepository())),
        ChangeNotifierProvider(create: (_) => BatchPLProvider(BatchRepository())),
        ChangeNotifierProvider(create: (_) => BatchWizardProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(ExpenseRepository())),
        ChangeNotifierProvider(create: (_) => SaleProvider(SaleRepository())),
        ChangeNotifierProvider(create: (_) => CustomerProvider(CustomerRepository())),
        ChangeNotifierProvider(create: (_) => MarketProvider(MarketRepository())),
        ChangeNotifierProvider(create: (_) => PartnerProvider(PartnerRepository())),
        ChangeNotifierProvider(create: (_) => ProductProvider(ProductRepository())),
        ChangeNotifierProvider(create: (_) => ReportProvider(ReportRepository())),
        ChangeNotifierProvider(create: (_) => TransactionProvider(TransactionRepository())),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const GreenMarketApp(),
    ),
  );
}

class GreenMarketApp extends StatelessWidget {
  const GreenMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Market',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) return const SplashPage();
    if (!auth.isAuthenticated) return const AuthNavigator();
    if (auth.needsOnboarding) return const OnboardingPage();
    return const MainShell();
  }
}
