import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';

class PartnerBalancePage extends ConsumerWidget {
  const PartnerBalancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Balances')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/settlement'),
        child: const Icon(Icons.swap_horiz),
      ),
      body: const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Partner Balances',
        subtitle: 'Track who owes what',
      ),
    );
  }
}
