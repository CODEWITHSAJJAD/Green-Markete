import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capability.dart';
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
                if (partner.role != 'owner') ...[
                  const Divider(height: 28),
                  Text('Role', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _roleChip(context, partner, businessId, 'purchaser', 'Purchaser'),
                      _roleChip(context, partner, businessId, 'seller', 'Seller'),
                      _roleChip(context, partner, businessId, 'both', 'Both'),
                      _roleChip(context, partner, businessId, 'accountant', 'Accountant'),
                      _roleChip(context, partner, businessId, 'partner', 'Partner'),
                    ],
                  ),
                  const Divider(height: 28),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow editing the other side'),
                    subtitle: const Text(
                      'Grants this partner write access on both sides '
                      '(e.g. a purchaser can also manage sales).',
                    ),
                    value: partner.manageOtherSide,
                    onChanged: (value) =>
                        _toggleManageOtherSide(context, partner, businessId, value),
                  ),
                  const Divider(height: 28),
                  Text('Active Permissions for this Business', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (_) {
                      final caps = CapabilityService(
                        partner.accessLevel ?? 'viewer',
                        sideRole: partner.role,
                        manageOtherSide: partner.manageOtherSide,
                      );
                      return Column(
                        children: [
                          _permissionRow(
                            theme,
                            MingCuteIcons.mgc_shopping_bag_2_line,
                            'Batches & Purchases',
                            caps.can(Capability.createBatch) || caps.can(Capability.recordPurchase),
                            'Create new batches & enter purchases',
                          ),
                          const SizedBox(height: 8),
                          _permissionRow(
                            theme,
                            MingCuteIcons.mgc_bill_line,
                            'Sales & Customers',
                            caps.can(Capability.recordSale) || caps.can(Capability.createCustomer),
                            'Record sales, issue bills & manage customers',
                          ),
                          const SizedBox(height: 8),
                          _permissionRow(
                            theme,
                            MingCuteIcons.mgc_wallet_3_line,
                            'Expenses & Settlements',
                            caps.can(Capability.addExpense) || caps.can(Capability.createSettlement),
                            'Log expenses & record partner/supplier settlements',
                          ),
                          const SizedBox(height: 8),
                          _permissionRow(
                            theme,
                            MingCuteIcons.mgc_truck_line,
                            'Transport & Vehicles',
                            caps.can(Capability.manageTransport),
                            'Create & assign vehicle transport loads',
                          ),
                          const SizedBox(height: 8),
                          _permissionRow(
                            theme,
                            MingCuteIcons.mgc_route_line,
                            'Batch Status Control',
                            caps.can(Capability.editBatch),
                            caps.can(Capability.closeBatch)
                                ? 'Full control (advance + close batches)'
                                : 'Advance batches up to selling status',
                          ),
                        ],
                      );
                    },
                  ),
                ],
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
    final ledger = transactionProvider.ledger ?? {};
    final data = (ledger['data'] as Map<String, dynamic>?) ?? ledger;
    final balance = (data['balance'] as Map<String, dynamic>?) ??
        (ledger['balance'] as Map<String, dynamic>?) ??
        {};
    final entries = (data['entries'] as List<dynamic>?) ??
        (ledger['entries'] as List<dynamic>?) ??
        [];

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

  Future<void> _toggleManageOtherSide(
    BuildContext context,
    PartnerModel partner,
    String businessId,
    bool value,
  ) async {
    final ok =
        await context.read<PartnerProvider>().updateManageOtherSide(partner.id, value, businessId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Other-side access ${value ? 'granted' : 'revoked'}' : 'Update failed',
          ),
        ),
      );
    }
  }

  Widget _roleChip(
    BuildContext context,
    PartnerModel partner,
    String businessId,
    String role,
    String label,
  ) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: partner.role == role,
      onSelected: (_) => _updateRole(context, partner, businessId, role),
      selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.18),
    );
  }

  Future<void> _updateRole(
    BuildContext context,
    PartnerModel partner,
    String businessId,
    String role,
  ) async {
    if (partner.role == role) return;
    final ok = await context.read<PartnerProvider>().updateRole(partner.id, role, businessId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Role updated to $role' : 'Role update failed')),
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

  Widget _permissionRow(
    ThemeData theme,
    IconData icon,
    String title,
    bool isGranted,
    String subtitle,
  ) {
    final color = isGranted ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isGranted
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isGranted ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGranted ? 'Allowed' : 'Disabled',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isGranted ? theme.colorScheme.primary : theme.colorScheme.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
