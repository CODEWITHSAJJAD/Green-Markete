import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
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
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final partnerProvider = context.watch<PartnerProvider>();
    final partners = partnerProvider.partners;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settlements Center',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          GreenCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Settlement Ledger',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Audit partner balance sheets and record cash or bank settlements across partners and equity holders.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PartnerSettlementPage()),
                    ),
                    icon: const Icon(HeroIcons.banknotes, size: 19),
                    label: Text(
                      'Record New Settlement',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Partner Ledgers & Accounts'),
          const SizedBox(height: 10),
          if (partnerProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (partnerProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(partnerProvider.error.toString(), style: GoogleFonts.inter(color: AppColors.rose)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<PartnerProvider>().load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (partners.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                icon: HeroIcons.users,
                title: 'No partners found',
                subtitle: 'Add team members or partners to begin recording inter-partner balances.',
              ),
            )
          else
            ...partners.map(
              (partner) => GreenCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PartnerBalancePage(
                      partnerId: partner.id,
                      partner: partner,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          partner.fullName.isNotEmpty ? partner.fullName[0].toUpperCase() : 'P',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            partner.phone ?? 'No phone number',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      HeroIcons.chevron_right,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
