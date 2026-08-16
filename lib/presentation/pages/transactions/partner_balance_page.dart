import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/partner_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/date_range_filter_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';

class PartnerBalancePage extends StatefulWidget {
  final String partnerId;
  final PartnerModel? partner;

  const PartnerBalancePage({super.key, required this.partnerId, this.partner});

  @override
  State<PartnerBalancePage> createState() => _PartnerBalancePageState();
}

class _PartnerBalancePageState extends State<PartnerBalancePage> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().loadLedger(widget.partnerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.partner?.fullName ?? 'Partner Balance',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        actions: [
          DateRangeFilterButton(
            value: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
        ],
      ),
      body: transactionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionProvider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                        const SizedBox(height: 12),
                        Text(transactionProvider.error.toString(), style: GoogleFonts.inter(color: AppColors.rose)),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => context.read<TransactionProvider>().loadLedger(widget.partnerId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildLedger(context, transactionProvider),
    );
  }

  Widget _buildLedger(BuildContext context, TransactionProvider transactionProvider) {
    final ledger = transactionProvider.ledger ?? {};
    final data = (ledger['data'] as Map<String, dynamic>?) ?? ledger;
    final entries = ((data['entries'] as List<dynamic>?) ??
            (ledger['entries'] as List<dynamic>?) ??
            [])
        .where((entry) {
      if (_range == null) return true;
      final dateStr = entry['date']?.toString() ?? '';
      final d = DateTime.tryParse(dateStr);
      if (d == null) return true;
      return !d.isBefore(_range!.start) && !d.isAfter(_range!.end);
    }).toList();
    final balance = (data['balance'] as Map<String, dynamic>?) ??
        (ledger['balance'] as Map<String, dynamic>?) ??
        {};

    final netBalance = (balance['net_balance'] as num?)?.toDouble() ?? 0;
    final totalSent = (balance['total_sent'] as num?)?.toDouble() ?? 0;
    final totalReceived = (balance['total_received'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        GreenCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Outstanding Balance',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_range != null)
                    Chip(
                      label: Text(
                        '${_range!.start.toString().split(' ').first} → ${_range!.end.toString().split(' ').first}',
                        style: GoogleFonts.inter(fontSize: 11),
                      ),
                      onDeleted: () => setState(() => _range = null),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(netBalance),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: netBalance >= 0 ? AppColors.emeraldDark : AppColors.rose,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Remitted / Sent',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(totalSent),
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Received',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(totalReceived),
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: EmptyState(
              icon: HeroIcons.arrows_right_left,
              title: 'No transactions in this period',
              subtitle: 'Transactions and remittances with this partner will appear here.',
            ),
          )
        else
          ...entries.map(
            (entry) => GreenCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: const Icon(HeroIcons.arrows_right_left, size: 18, color: AppColors.primary),
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
                          '${entry['date'] ?? '-'} • ${(entry['type'] ?? '-').toString().toUpperCase()}',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format((entry['amount'] as num?)?.toDouble() ?? 0),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
