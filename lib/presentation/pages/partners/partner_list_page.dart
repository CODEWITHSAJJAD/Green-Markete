import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/capability.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'create_partner_page.dart';
import 'partner_profile_page.dart';

class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all'; // 'all', 'employees', 'partners'

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    if (!context.read<AuthProvider>().capabilities.can(Capability.createPartner)) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePartnerPage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<PartnerProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId ?? '';
    final currentBusiness =
        auth.businesses.where((b) => b.id == auth.businessId).firstOrNull;
    final isSoloBusiness = currentBusiness?.businessType == 'single';

    final search = _searchCtrl.text.trim();
    final partnerProvider = context.watch<PartnerProvider>();
    final allPartners = search.isEmpty ? partnerProvider.partners : partnerProvider.searchResults;

    final filteredPartners = allPartners.where((p) {
      if (_filter == 'employees') return p.role != 'partner';
      if (_filter == 'partners') return p.role == 'partner';
      return true;
    }).toList();

    final employeeCount = allPartners.where((p) => p.role != 'partner').length;
    final partnerCount = allPartners.where((p) => p.role == 'partner').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSoloBusiness ? 'Employees & Staff' : 'Partners & Staff'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
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
                Text(
                  isSoloBusiness ? 'Business Staff & Access' : 'Business Partners & Staff',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isSoloBusiness
                      ? 'Manage purchasers, sellers, accountants, and staff members.'
                      : 'Manage purchasers, sellers, accountants, employees, and equity partners.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (query) {
                    context.read<PartnerProvider>().search(query, businessId);
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: Icon(MingCuteIcons.mgc_search_2_line),
                  ),
                ),
                if (!isSoloBusiness) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('All (${allPartners.length})'),
                          selected: _filter == 'all',
                          onSelected: (_) => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Staff / Employees ($employeeCount)'),
                          selected: _filter == 'employees',
                          onSelected: (_) => setState(() => _filter = 'employees'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Equity Partners ($partnerCount)'),
                          selected: _filter == 'partners',
                          onSelected: (_) => setState(() => _filter = 'partners'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
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
          else if (filteredPartners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: EmptyState(
                icon: MingCuteIcons.mgc_user_3_line,
                title: _filter == 'employees'
                    ? 'No employees found'
                    : _filter == 'partners'
                        ? 'No partners found'
                        : 'No members found',
                subtitle: isSoloBusiness
                    ? 'Add employees to assign purchasing, selling, or accounting duties.'
                    : 'Add staff or partners to build your operations network.',
                actionLabel: isSoloBusiness ? 'Add Employee' : 'Add Member',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: filteredPartners
                  .map(
                    (partner) {
                      final isEmployee = partner.role != 'partner' && partner.role != 'owner';
                      return GreenCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PartnerProfilePage(
                              partnerId: partner.id,
                              initialPartner: partner,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                partner.fullName.substring(0, 1).toUpperCase(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          partner.fullName,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isEmployee
                                              ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isEmployee ? 'Staff' : 'Partner',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: isEmployee
                                                ? theme.colorScheme.secondary
                                                : theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      describeSide(partner.role),
                                      partner.city ?? '',
                                      partner.phone ?? ''
                                    ].where((item) => item.isNotEmpty).join('  •  '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _accessBadge(theme, partner.accessLevel ?? 'viewer'),
                                      const SizedBox(width: 6),
                                      _claimedBadge(theme, partner.isClaimed),
                                      if (partner.manageOtherSide) ...[
                                        const SizedBox(width: 6),
                                        _crossSideBadge(theme),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: context
              .watch<AuthProvider>()
              .capabilities
              .can(Capability.createPartner)
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _openCreate,
              icon: const Icon(MingCuteIcons.mgc_user_4_line),
              label: Text(isSoloBusiness ? 'Add Employee' : 'Add Member'),
            )
          : null,
    );
  }

  Widget _accessBadge(ThemeData theme, String accessLevel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accessLevel == 'editor'
            ? theme.colorScheme.secondary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        describeAccess(accessLevel),
        style: theme.textTheme.labelSmall?.copyWith(
          color: accessLevel == 'editor'
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _crossSideBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.inversePrimary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Both sides',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _claimedBadge(ThemeData theme, bool isClaimed) {    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isClaimed
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : theme.colorScheme.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isClaimed ? 'Claimed' : 'Pending',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isClaimed
              ? theme.colorScheme.primary
              : theme.colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
