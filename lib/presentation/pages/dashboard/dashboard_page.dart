import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import 'widgets/summary_cards.dart';
import 'widgets/active_batches_card.dart';
import 'widgets/credit_alerts_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/recent_transactions.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final businessId = authState.user?.businessId ?? authState.user?.id ?? '';
    final summaryAsync = ref.watch(dashboardSummaryProvider(businessId));
    final batchesAsync = ref.watch(activeBatchesProvider(businessId));
    final overdueAsync = ref.watch(overdueCustomersProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Green Market'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.go('/settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider(businessId));
          ref.invalidate(activeBatchesProvider(businessId));
          ref.invalidate(overdueCustomersProvider(businessId));
        },
        child: ListView(
          children: [
            const SizedBox(height: 8),
            summaryAsync.when(
              data: (summary) => SummaryCards(summary: summary),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(height: 100),
            ),
            QuickActionsRow(),
            batchesAsync.when(
              data: (batches) => ActiveBatchesCard(batches: batches),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            overdueAsync.when(
              data: (overdue) => CreditAlertsCard(overdueCustomers: overdue),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            RecentTransactions(transactions: const []),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
