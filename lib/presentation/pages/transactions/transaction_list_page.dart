import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import 'partner_balance_page.dart';
import 'partner_settlement_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<PartnerProvider>().load(businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final partnerProvider = context.watch<PartnerProvider>();
    final partners = partnerProvider.partners;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Settlements')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondary.withValues(alpha: 0.10),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settlement center', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Review partner balances and record inter-partner cash or bank settlements.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PartnerSettlementPage()),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Record Settlement'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Partner ledgers', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (partnerProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (partnerProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(partnerProvider.error.toString()),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<PartnerProvider>().load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (partners.isEmpty)
            const Text('No partners available for settlement tracking yet.')
          else
            Column(
              children: partners
                  .map(
                    (partner) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(partner.fullName, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(partner.role, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PartnerBalancePage(partnerId: partner.id, partner: partner),
                              ),
                            ),
                            child: const Text('View Ledger'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
