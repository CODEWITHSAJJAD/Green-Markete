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
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.capabilities.isOwner;
    final partner = partnerProvider.partners.cast<PartnerModel?>().firstWhere(
          (item) => item?.id == widget.partnerId,
          orElse: () => widget.initialPartner,
        );
    if (partner == null) {
      return const Center(child: Text('Partner not found'));
    }

    final isEmployee = partner.role != 'partner' && partner.role != 'owner';

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
                          [partner.role.toUpperCase(), partner.city, partner.phone]
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
                  _chip(theme, isEmployee ? 'Type: Employee / Staff' : 'Type: Business Partner'),
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
        if (isOwner)
          GreenCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Access & Role Management',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Owner Controls',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Member Type', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      avatar: const Icon(MingCuteIcons.mgc_user_3_line, size: 16),
                      label: const Text('Staff / Employee'),
                      selected: partner.memberType == 'employee',
                      onSelected: (_) => _updateMemberType(context, partner, businessId, 'employee'),
                    ),
                    ChoiceChip(
                      avatar: const Icon(MingCuteIcons.mgc_group_line, size: 16),
                      label: const Text('Business Partner'),
                      selected: partner.memberType == 'partner',
                      onSelected: (_) => _updateMemberType(context, partner, businessId, 'partner'),
                    ),
                  ],
                ),
                if (partner.role != 'owner') ...[
                  const Divider(height: 28),
                  Text('Assigned Role', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _roleChip(context, partner, businessId, 'purchaser', 'Purchaser'),
                      _roleChip(context, partner, businessId, 'seller', 'Seller'),
                      _roleChip(context, partner, businessId, 'both', 'Both (Purchaser & Seller)'),
                      _roleChip(context, partner, businessId, 'accountant', 'Accountant'),
                    ],
                  ),
                ],
                const Divider(height: 28),
                Text('Access Level', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Viewer (Scoped Access)'),
                      selected: (partner.accessLevel ?? 'viewer') == 'viewer',
                      onSelected: (_) => _updateAccess(context, partner, businessId, 'viewer'),
                    ),
                    ChoiceChip(
                      label: const Text('Editor (Elevated Access)'),
                      selected: (partner.accessLevel ?? 'viewer') == 'editor',
                      onSelected: (_) => _updateAccess(context, partner, businessId, 'editor'),
                    ),
                  ],
                ),
                if (partner.role != 'owner') ...[
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Individual Permissions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to toggle',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (_) {
                      final caps = CapabilityService(
                        partner.accessLevel ?? 'viewer',
                        sideRole: partner.role,
                        manageOtherSide: partner.manageOtherSide,
                        customPermissions: partner.permissions,
                      );
                      final hasPurchasing = caps.can(Capability.createBatch) || caps.can(Capability.recordPurchase);
                      final hasSelling = caps.can(Capability.recordSale) || caps.can(Capability.createCustomer);
                      final hasExpenses = caps.can(Capability.addExpense) || caps.can(Capability.createSettlement);
                      final hasTransport = caps.can(Capability.manageTransport);
                      final hasBatchControl = caps.isEditor || caps.can(Capability.closeBatch);

                      return Column(
                        children: [
                          _permissionToggleRow(
                            theme,
                            MingCuteIcons.mgc_shopping_bag_2_line,
                            'Batches & Purchases',
                            'Create new batches & log purchases',
                            hasPurchasing,
                            (val) => _togglePermission(context, partner, businessId, 'can_purchase', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            theme,
                            MingCuteIcons.mgc_bill_line,
                            'Sales & Customers',
                            'Record sales, create customers & invoices',
                            hasSelling,
                            (val) => _togglePermission(context, partner, businessId, 'can_sell', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            theme,
                            MingCuteIcons.mgc_wallet_3_line,
                            'Expenses & Settlements',
                            'Log expenses & record partner/supplier settlements',
                            hasExpenses,
                            (val) => _togglePermission(context, partner, businessId, 'can_expense', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            theme,
                            MingCuteIcons.mgc_truck_line,
                            'Transport & Vehicles',
                            'Create & assign vehicle transport loads',
                            hasTransport,
                            (val) => _togglePermission(context, partner, businessId, 'can_transport', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            theme,
                            MingCuteIcons.mgc_route_line,
                            'Batch Status & Closure Control',
                            hasBatchControl
                                ? 'Elevated access (can advance & close batches)'
                                : 'Scoped access (cannot advance to closed)',
                            hasBatchControl,
                            (val) => _togglePermission(context, partner, businessId, 'can_close_batch', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            theme,
                            MingCuteIcons.mgc_transfer_line,
                            'Cross-Side Operations',
                            'Grants full write access on both business sides',
                            partner.manageOtherSide,
                            (val) => _toggleManageOtherSide(context, partner, businessId, val),
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
        if (entries.isEmpty)
          GreenCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(MingCuteIcons.mgc_history_line, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No ledger entries yet. Payments, advances, and batch settlements recorded for this partner will appear here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.take(5).map(
                (entry) => GreenCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (entry['type'] == 'received' ? theme.colorScheme.primary : theme.colorScheme.error)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        entry['type'] == 'received' ? MingCuteIcons.mgc_arrow_down_line : MingCuteIcons.mgc_arrow_up_line,
                        size: 16,
                        color: entry['type'] == 'received' ? theme.colorScheme.primary : theme.colorScheme.error,
                      ),
                    ),
                    title: Text(entry['description']?.toString() ?? '-'),
                    subtitle: Text(entry['date']?.toString() ?? '-'),
                    trailing: Text(
                      '${entry['type'] == 'received' ? '+' : '-'} ${CurrencyFormatter.format((entry['amount'] as num?)?.toDouble() ?? 0)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: entry['type'] == 'received' ? theme.colorScheme.primary : theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
        SnackBar(
          content: Text(ok ? 'Role updated to $role' : 'Role update failed'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _updateMemberType(
    BuildContext context,
    PartnerModel partner,
    String businessId,
    String memberType,
  ) async {
    if (partner.memberType == memberType) return;
    final ok = await context.read<PartnerProvider>().updateMemberType(partner.id, memberType, businessId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Member type set to ${memberType == 'employee' ? 'Staff / Employee' : 'Business Partner'}'
                : 'Failed to update member type',
          ),
          duration: const Duration(seconds: 1),
        ),
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

  Widget _permissionToggleRow(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    bool isGranted,
    ValueChanged<bool> onToggle,
  ) {
    final color = isGranted ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isGranted
            ? theme.colorScheme.primary.withValues(alpha: 0.07)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isGranted ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: isGranted,
            onChanged: onToggle,
            activeTrackColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _togglePermission(
    BuildContext context,
    PartnerModel partner,
    String businessId,
    String permissionKey,
    bool enable,
  ) async {
    final ok = await context.read<PartnerProvider>().updatePermission(
      partner.id,
      permissionKey,
      enable,
      businessId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Permission updated successfully' : 'Failed to update permission'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
