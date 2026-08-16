import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (businessId.isNotEmpty)
        context.read<PartnerProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    if (!context.read<AuthProvider>().capabilities.can(
      Capability.createPartner,
    )) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreatePartnerPage()));
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<PartnerProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId ?? '';
    final currentBusiness = auth.businesses
        .where((b) => b.id == auth.businessId)
        .firstOrNull;
    final isSoloBusiness = currentBusiness?.businessType == 'single';

    final query = _searchCtrl.text.trim().toLowerCase();
    final partnerProvider = context.watch<PartnerProvider>();
    final allPartners = query.isEmpty
        ? partnerProvider.partners
        : partnerProvider.partners.where((p) {
            final name = p.fullName.toLowerCase();
            final phone = (p.phone ?? '').toLowerCase();
            final city = (p.city ?? '').toLowerCase();
            final role = p.role.toLowerCase();
            final type = p.memberType.toLowerCase();
            return name.contains(query) ||
                phone.contains(query) ||
                city.contains(query) ||
                role.contains(query) ||
                type.contains(query);
          }).toList();

    final filteredPartners = allPartners.where((p) {
      if (_filter == 'employees') return p.isEmployee;
      if (_filter == 'partners') return p.isPartner;
      return true;
    }).toList();

    final employeeCount = allPartners.where((p) => p.isEmployee).length;
    final partnerCount = allPartners.where((p) => p.isPartner).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isSoloBusiness ? 'Staff & Employees' : 'Partners & Team',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(
                    HeroIcons.users,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSoloBusiness
                            ? 'Staff & Team Directory'
                            : 'Team Roles & Access Control',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage member types, side responsibilities, and operational permissions.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by member name, phone, city, or role...',
              prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(HeroIcons.x_circle, size: 18),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    )
                  : null,
            ),
          ),
          if (!isSoloBusiness) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All Members (${allPartners.length})'),
                    selected: _filter == 'all',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: _filter == 'all'
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: _filter == 'all'
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Business Partners ($partnerCount)'),
                    selected: _filter == 'partners',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: _filter == 'partners'
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: _filter == 'partners'
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) => setState(() => _filter = 'partners'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Staff / Employees ($employeeCount)'),
                    selected: _filter == 'employees',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: _filter == 'employees'
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: _filter == 'employees'
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) => setState(() => _filter = 'employees'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (partnerProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (partnerProvider.error != null)
            GreenCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                  const SizedBox(height: 12),
                  Text(partnerProvider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => partnerProvider.load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (filteredPartners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: HeroIcons.user_group,
                title: query.isNotEmpty
                    ? 'No matching members found'
                    : 'No team members added',
                subtitle: query.isNotEmpty
                    ? 'Try modifying your search query.'
                    : 'Invite partners, Customers, sellers, and accountants to collaborate in your business.',
                actionLabel: auth.capabilities.can(Capability.createPartner)
                    ? 'Add Member'
                    : null,
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: filteredPartners.map((partner) {
                final isOwner = partner.role == 'owner';
                final isPartnerType = partner.isPartner;

                return GreenCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PartnerProfilePage(partnerId: partner.id),
                      ),
                    );
                    if (!mounted) return;
                    if (businessId.isNotEmpty) {
                      context.read<PartnerProvider>().load(businessId);
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isOwner
                            ? AppColors.primarySurface
                            : isPartnerType
                            ? AppColors.indigoSurface
                            : AppColors.surfaceAlt,
                        child: Text(
                          partner.fullName.isNotEmpty
                              ? partner.fullName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: isOwner
                                ? AppColors.primary
                                : isPartnerType
                                ? AppColors.indigo
                                : AppColors.textPrimary,
                            fontSize: 15,
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
                                Flexible(
                                  child: Text(
                                    partner.fullName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Owner',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                partner.role.toUpperCase(),
                                if (partner.city != null &&
                                    partner.city!.isNotEmpty)
                                  partner.city,
                                if (partner.phone != null &&
                                    partner.phone!.isNotEmpty)
                                  partner.phone,
                              ].where((e) => e != null).join(' • '),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPartnerType
                              ? AppColors.indigoSurface
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPartnerType
                                ? AppColors.indigo.withValues(alpha: 0.2)
                                : AppColors.divider,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isPartnerType ? 'Partner' : 'Staff',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isPartnerType
                                ? AppColors.indigo
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      floatingActionButton: auth.capabilities.can(Capability.createPartner)
          ? FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: _openCreate,
              icon: const Icon(HeroIcons.user_plus, size: 18),
              label: Text(
                'Add Member',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }
}
