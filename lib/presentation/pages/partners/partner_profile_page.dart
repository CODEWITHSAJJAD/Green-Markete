import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/green_card.dart';
import '../transactions/partner_balance_page.dart';

class PartnerProfilePage extends StatefulWidget {
  final String partnerId;
  final PartnerModel? initialPartner;

  const PartnerProfilePage({super.key, required this.partnerId, this.initialPartner});

  @override
  State<PartnerProfilePage> createState() => _PartnerProfilePageState();
}

class _PartnerProfilePageState extends State<PartnerProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<PartnerProvider>().load(businessId);
      context.read<TransactionProvider>().loadLedger(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final currentRole = context.watch<AuthProvider>().user?.role ?? '';
    final partnerProvider = context.watch<PartnerProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Profile')),
      body: partnerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : partnerProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
              : _buildContent(
                  context,
                  theme,
                  businessId,
                  currentRole,
                  partnerProvider,
                  transactionProvider,
                ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    String businessId,
    String currentRole,
    PartnerProvider partnerProvider,
    TransactionProvider transactionProvider,
  ) {
    final partner = widget.initialPartner ??
        partnerProvider.partners.cast<PartnerModel?>().firstWhere(
              (item) => item?.id == widget.partnerId,
              orElse: () => null,
            );
    if (partner == null) {
      return const Center(child: Text('Partner not found'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GreenCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(partner.fullName.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.fullName, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          [partner.role, partner.city, partner.phone]
                              .where((item) => item != null && item.isNotEmpty)
                              .join('  •  '),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip(theme, 'Access: ${partner.accessLevel ?? 'viewer'}'),
                  _chip(theme, partner.isClaimed ? 'Claimed profile' : 'Invitation pending'),
                ],
              ),
              if (!partner.isClaimed) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await PartnerRepository().invite(partner.id);
                    if (!context.mounted) return;
                    context.read<PartnerProvider>().load(businessId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitation sent')),
                    );
                  },
                  icon: const Icon(MingCuteIcons.mgc_send_line),
                  label: const Text('Resend Invitation'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (currentRole == 'owner')
          GreenCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Access Management', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Viewer'),
                      selected: (partner.accessLevel ?? 'viewer') == 'viewer',
                      onSelected: (_) => _updateAccess(context, partner, businessId, 'viewer'),
                    ),
                    ChoiceChip(
                      label: const Text('Editor'),
                      selected: (partner.accessLevel ?? 'viewer') == 'editor',
                      onSelected: (_) => _updateAccess(context, partner, businessId, 'editor'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (transactionProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (transactionProvider.error != null)
          Column(
            children: [
              Text(transactionProvider.error.toString()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.read<TransactionProvider>().loadLedger(widget.partnerId),
                child: const Text('Retry'),
              ),
            ],
          )
        else
          _buildLedger(context, theme, transactionProvider, partner),
      ],
    );
  }

  Widget _buildLedger(
    BuildContext context,
    ThemeData theme,
    TransactionProvider transactionProvider,
    PartnerModel partner,
  ) {
    final ledger = transactionProvider.ledger;
    final data = ledger?['data'] as Map<String, dynamic>? ?? {};
    final balance = data['balance'] as Map<String, dynamic>? ?? {};
    final entries = data['entries'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ledger Snapshot', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PartnerBalancePage(partnerId: widget.partnerId, partner: partner),
                ),
              ),
              child: const Text('Full Ledger'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _stat(theme, 'Sent', (balance['total_sent'] as num?)?.toDouble() ?? 0)),
            const SizedBox(width: 12),
            Expanded(child: _stat(theme, 'Received', (balance['total_received'] as num?)?.toDouble() ?? 0)),
          ],
        ),
        const SizedBox(height: 12),
        _stat(theme, 'Net Balance', (balance['net_balance'] as num?)?.toDouble() ?? 0, fullWidth: true),
        const SizedBox(height: 12),
        ...entries.take(5).map(
              (entry) => GreenCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  title: Text(entry['description']?.toString() ?? '-'),
                  subtitle: Text(entry['date']?.toString() ?? '-'),
                  trailing: Text(CurrencyFormatter.format((entry['amount'] as num?)?.toDouble() ?? 0)),
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _updateAccess(
    BuildContext context,
    PartnerModel partner,
    String businessId,
    String accessLevel,
  ) async {
    await context.read<PartnerProvider>().updateAccess(partner.id, accessLevel, businessId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access updated to $accessLevel')),
      );
    }
  }

  Widget _chip(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }

  Widget _stat(ThemeData theme, String title, double value, {bool fullWidth = false}) {
    return GreenCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(value), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
