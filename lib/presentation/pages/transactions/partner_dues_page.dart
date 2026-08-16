import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_due_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_dues_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../batches/batch_detail_page.dart';
import 'partner_settlement_page.dart';

class PartnerDuesPage extends StatefulWidget {
  const PartnerDuesPage({super.key});

  @override
  State<PartnerDuesPage> createState() => _PartnerDuesPageState();
}

class _PartnerDuesPageState extends State<PartnerDuesPage> {
  String get _businessId => context.read<AuthProvider>().businessId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = _businessId;
      if (id.isNotEmpty) {
        context.read<PartnerProvider>().load(id);
        context.read<PartnerDuesProvider>().load(id);
      }
    });
  }

  Future<void> _reload() async {
    final id = _businessId;
    if (id.isEmpty) return;
    await context.read<PartnerDuesProvider>().load(id);
  }

  String _partnerName(String id) {
    final partners = context.read<PartnerProvider>().partners;
    return partners
            .where((p) => p.id == id)
            .map((p) => p.fullName)
            .firstOrNull ??
        id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartnerDuesProvider>();
    context.watch<PartnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Partner Dues',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            GreenCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partner Settlement Dues',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purchaser-side procurement bills owed to seller partners, payable in full or split installments.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          'Total Bill Basis',
                          CurrencyFormatter.format(provider.totalBill),
                          AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricTile(
                          'Total Settled',
                          CurrencyFormatter.format(provider.totalPaid),
                          AppColors.emeraldDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricTile(
                          'Outstanding',
                          CurrencyFormatter.format(provider.totalOutstanding),
                          provider.totalOutstanding > 0 ? AppColors.rose : AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PartnerSettlementPage(),
                          ),
                        );
                        if (mounted) _reload();
                      },
                      icon: const Icon(HeroIcons.banknotes, size: 18, color: AppColors.primary),
                      label: Text(
                        'Record Partner Settlement',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(provider.error.toString(), style: GoogleFonts.inter(color: AppColors.rose)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (provider.dues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: EmptyState(
                  icon: HeroIcons.wallet,
                  title: 'No dues to partners',
                  subtitle: 'Add seller partners to batch purchases and their calculated bill splits will appear here.',
                ),
              )
            else
              ...provider.dues.map((d) => _dueCard(d)),
          ],
        ),
      ),
    );
  }

  Widget _dueCard(PartnerDueModel due) {
    final name = _partnerName(due.partnerId);
    final remaining = due.totalRemaining;
    final settled = remaining <= 0.01;

    return GreenCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: settled ? AppColors.emeraldSurface : AppColors.roseSurface,
          child: Icon(
            settled ? HeroIcons.check_circle : HeroIcons.clock,
            color: settled ? AppColors.emeraldDark : AppColors.rose,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Bill ${CurrencyFormatter.format(due.totalBill)} • Paid ${CurrencyFormatter.format(due.totalPaid)}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(due.totalRemaining),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: settled ? AppColors.emeraldDark : AppColors.rose,
              ),
            ),
            Text(
              settled ? 'Settled' : 'Payable Due',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: settled ? AppColors.emeraldDark : AppColors.rose,
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 16),
          for (final b in due.batches) ...[
            if (b != due.batches.first) const Divider(height: 14),
            _batchDueRow(b),
          ],
        ],
      ),
    );
  }

  Widget _batchDueRow(BatchDueModel due) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due.batchCode,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (due.productName != null && due.productName!.isNotEmpty)
                    Text(
                      due.productName!,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BatchDetailPage(batchId: due.batchId),
                ),
              ),
              child: Text(
                'Open Batch',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bill: ${CurrencyFormatter.format(due.bill)} • Paid: ${CurrencyFormatter.format(due.paid)}',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textTertiary),
            ),
            Text(
              CurrencyFormatter.format(due.remaining),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: due.isFullySettled ? AppColors.emeraldDark : AppColors.rose,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
