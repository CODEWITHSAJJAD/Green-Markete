import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Member Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: partnerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : partnerProvider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                        const SizedBox(height: 12),
                        Text(partnerProvider.error.toString(), style: GoogleFonts.inter(color: AppColors.rose)),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => context.read<PartnerProvider>().load(businessId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
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

    final isEmployee = partner.memberType == 'employee';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                    backgroundColor: AppColors.primary,
                    child: Text(
                      partner.fullName.isNotEmpty ? partner.fullName[0].toUpperCase() : 'P',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 17.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [partner.role.toUpperCase(), partner.city, partner.phone]
                              .where((item) => item != null && item.isNotEmpty)
                              .join(' • '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(isEmployee ? 'Staff / Employee' : 'Business Partner', isPrimary: true),
                  _chip('Access: ${(partner.accessLevel ?? 'viewer').toUpperCase()}'),
                  _chip(
                    partner.isClaimed ? 'Account Linked' : 'Invitation Pending',
                    isSuccess: partner.isClaimed,
                  ),
                ],
              ),
              if (!partner.isClaimed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await PartnerRepository().invite(partner.id);
                      if (!context.mounted) return;
                      context.read<PartnerProvider>().load(businessId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation SMS resent to partner')),
                      );
                    },
                    icon: const Icon(HeroIcons.paper_airplane, size: 18),
                    label: Text(
                      'Resend Invite Link',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isOwner)
          GreenCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Access & Role Controls',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Text(
                        'Owner Settings',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Member Classification',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      avatar: const Icon(HeroIcons.user, size: 16),
                      label: const Text('Staff / Employee'),
                      selected: partner.memberType == 'employee',
                      onSelected: (_) => _updateMemberType(context, partner, businessId, 'employee'),
                    ),
                    ChoiceChip(
                      avatar: const Icon(HeroIcons.briefcase, size: 16),
                      label: const Text('Business Partner'),
                      selected: partner.memberType == 'partner',
                      onSelected: (_) => _updateMemberType(context, partner, businessId, 'partner'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Assigned Role',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _roleChip(context, partner, businessId, 'purchaser', 'Purchaser'),
                    _roleChip(context, partner, businessId, 'seller', 'Seller'),
                    _roleChip(context, partner, businessId, 'both', 'Manager (Both)'),
                    _roleChip(context, partner, businessId, 'accountant', 'Accountant'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Authority Level',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Elevated (Editor)'),
                      selected: (partner.accessLevel ?? 'viewer') == 'editor',
                      onSelected: (_) => _updateAccess(context, partner, businessId, 'editor'),
                    ),
                    ChoiceChip(
                      label: const Text('Scoped (Viewer)'),
                      selected: (partner.accessLevel ?? 'viewer') == 'viewer',
                      onSelected: (_) => _updateAccess(context, partner, businessId, 'viewer'),
                    ),
                  ],
                ),
                if (partner.role != 'owner') ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(HeroIcons.shield_check, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Fine-Grained Permissions',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
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
                      final hasPurchasing = partner.permissions?['can_purchase'] ??
                          (caps.can(Capability.createBatch) || caps.can(Capability.recordPurchase));
                      final hasSelling = partner.permissions?['can_sell'] ??
                          (caps.can(Capability.recordSale) || caps.can(Capability.createCustomer));
                      final hasExpenses = partner.permissions?['can_expense'] ??
                          (caps.can(Capability.addExpense) || caps.can(Capability.createSettlement));
                      final hasTransport =
                          partner.permissions?['can_transport'] ?? caps.can(Capability.manageTransport);
                      final hasBatchControl = partner.permissions?['can_close_batch'] ??
                          (caps.isEditor && caps.can(Capability.closeBatch));

                      return Column(
                        children: [
                          _permissionToggleRow(
                            HeroIcons.shopping_bag,
                            'Batches & Purchases',
                            'Create new batches & log purchases',
                            hasPurchasing,
                            (val) => _togglePermission(context, partner, businessId, 'can_purchase', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            HeroIcons.document_text,
                            'Sales & Customers',
                            'Record sales, create customers & invoices',
                            hasSelling,
                            (val) => _togglePermission(context, partner, businessId, 'can_sell', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            HeroIcons.wallet,
                            'Expenses & Settlements',
                            'Log expenses & record partner/supplier settlements',
                            hasExpenses,
                            (val) => _togglePermission(context, partner, businessId, 'can_expense', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            HeroIcons.truck,
                            'Transport & Vehicles',
                            'Create & assign vehicle transport loads',
                            hasTransport,
                            (val) => _togglePermission(context, partner, businessId, 'can_transport', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            HeroIcons.arrow_path,
                            'Batch Status & Closure Control',
                            hasBatchControl
                                ? 'Elevated access (can advance & close batches)'
                                : 'Scoped access (cannot advance to closed)',
                            hasBatchControl,
                            (val) => _togglePermission(context, partner, businessId, 'can_close_batch', val),
                          ),
                          const SizedBox(height: 8),
                          _permissionToggleRow(
                            HeroIcons.arrows_right_left,
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
            Text(
              'Ledger Snapshot',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PartnerBalancePage(partnerId: widget.partnerId, partner: partner),
                ),
              ),
              child: Text(
                'Full Statement',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _stat('Total Sent', (balance['total_sent'] as num?)?.toDouble() ?? 0)),
            const SizedBox(width: 10),
            Expanded(child: _stat('Total Received', (balance['total_received'] as num?)?.toDouble() ?? 0)),
          ],
        ),
        const SizedBox(height: 10),
        _stat('Net Outstanding Balance', (balance['net_balance'] as num?)?.toDouble() ?? 0, fullWidth: true),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          GreenCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(HeroIcons.clock, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No ledger entries yet. Settlements and transactions recorded for this partner will appear here.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.take(5).map(
                (entry) => GreenCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (entry['type'] == 'received' ? AppColors.emeraldSurface : AppColors.roseSurface),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entry['type'] == 'received' ? HeroIcons.arrow_down_left : HeroIcons.arrow_up_right,
                          size: 16,
                          color: entry['type'] == 'received' ? AppColors.emeraldDark : AppColors.rose,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry['description']?.toString() ?? 'Transaction',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry['date']?.toString() ?? '-',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry['type'] == 'received' ? '+' : '-'} ${CurrencyFormatter.format((entry['amount'] as num?)?.toDouble() ?? 0)}',
                        style: GoogleFonts.inter(
                          color: entry['type'] == 'received' ? AppColors.emeraldDark : AppColors.rose,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
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
            ok ? 'Cross-side write access ${value ? 'granted' : 'revoked'}' : 'Update failed',
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
    final isSelected = partner.role == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _updateRole(context, partner, businessId, role),
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

  Widget _chip(String text, {bool isPrimary = false, bool isSuccess = false}) {
    Color bg = AppColors.surfaceAlt;
    Color fg = AppColors.textSecondary;
    if (isPrimary) {
      bg = AppColors.primarySurface;
      fg = AppColors.primary;
    } else if (isSuccess) {
      bg = AppColors.emeraldSurface;
      fg = AppColors.emeraldDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _stat(String title, double value, {bool fullWidth = false}) {
    return GreenCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(value),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionToggleRow(
    IconData icon,
    String title,
    String subtitle,
    bool isGranted,
    ValueChanged<bool> onToggle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isGranted ? AppColors.primarySurface : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? AppColors.primary.withValues(alpha: 0.25) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.primary : AppColors.textTertiary).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: isGranted ? AppColors.primary : AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isGranted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
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
            activeTrackColor: AppColors.primary,
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
