import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
import '../green_card.dart';
import 'batch_dialogs.dart';
import 'batch_metric_card.dart';

class BatchSettlementsTab extends StatefulWidget {
  final BatchModel batch;

  const BatchSettlementsTab({super.key, required this.batch});

  @override
  State<BatchSettlementsTab> createState() => _BatchSettlementsTabState();
}

class _BatchSettlementsTabState extends State<BatchSettlementsTab> {
  String? _ledgerSellerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plProvider = context.watch<BatchPLProvider>();
    final detailProvider = context.watch<BatchDetailProvider>();
    final partnerProvider = context.watch<PartnerProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final pl = plProvider.pl;

    final batch = widget.batch;
    final batchPartners = detailProvider.batchPartners;
    final sellers = batchPartners
        .where((p) => p['role'] == 'seller' || p['role'] == 'both')
        .toList();

    String? sellerId;
    String sellerName = 'Seller';

    if (sellers.isNotEmpty) {
      sellerId = sellers.first['partner_id'] as String?;
      if (sellerId != null) {
        sellerName = partnerProvider.partners
                .where((p) => p.id == sellerId)
                .map((p) => p.fullName)
                .firstOrNull ??
            (sellers.first['name'] as String?) ??
            'Seller';
      }
    } else {
      final fallbackSeller = partnerProvider.partners
          .where((p) => p.role == 'seller' || p.role == 'both' || p.role == 'owner')
          .firstOrNull;
      if (fallbackSeller != null) {
        sellerId = fallbackSeller.id;
        sellerName = fallbackSeller.fullName;
      }
    }

    if (sellerId != null && _ledgerSellerId != sellerId) {
      _ledgerSellerId = sellerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<TransactionProvider>().loadLedger(sellerId!);
      });
    }

    final ledgerRows = txProvider.ledger?['transactions'];
    final ledgerTxs = ledgerRows is List
        ? ledgerRows
            .whereType<Map<String, dynamic>>()
            .map(TransactionModel.fromJson)
            .toList()
        : <TransactionModel>[];
    final settledForBatch = ledgerTxs
        .where(
          (t) =>
              (t.notes?.contains(batch.batchCode) ?? false) ||
              (t.reference?.contains(batch.batchCode) ?? false),
        )
        .where((t) => sellerId == null || t.toPartnerId == sellerId)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final purchaseCost = pl?.costBreakdown.purchaseCost ?? batch.totalPurchaseCost;
    final purchaserDaily = pl?.costBreakdown.purchaserDailyCharges ??
        batchPartners.where((p) => p['role'] == 'purchaser').fold<double>(
              0,
              (s, p) =>
                  s +
                  ((p['daily_charge_rate'] as num?)?.toDouble() ?? 0) *
                      ((p['days_involved'] as num?)?.toInt() ?? 1),
            );
    final purchaserExpenses = pl?.costBreakdown.purchaserExpenses ??
        expenseProvider.expenses
            .where((e) => e.expenseSide == 'purchaser')
            .fold<double>(0, (s, e) => s + e.amount);
    final packingCost = pl?.costBreakdown.packingCost ??
        detailProvider.packingRecords.fold<double>(
          0,
          (s, p) => s + p.totalPackingCost,
        );
    final transport = pl?.costBreakdown.transportCost ??
        detailProvider.vehicleLoads.fold<double>(
          0,
          (s, l) => s + l.totalCost,
        );
    final transportInBill = batch.transportPaidBy == 'purchaser' ? transport : 0.0;
    final owed = purchaseCost + purchaserDaily + purchaserExpenses + packingCost + transportInBill;
    final remaining = (owed - settledForBatch).clamp(0, double.infinity).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        GreenCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primarySurface,
                    child: const Icon(
                      HeroIcons.user,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller / Receiving Partner',
                          style: GoogleFonts.inter(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          sellerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildBatchCostLine(theme, 'Purchase Procurement Cost', purchaseCost),
              buildBatchCostLine(theme, 'Purchaser Local Expenses', purchaserExpenses),
              buildBatchCostLine(theme, 'Purchaser Daily Charges', purchaserDaily),
              buildBatchCostLine(theme, 'Packing & Labor Cost', packingCost),
              if (batch.transportPaidBy == 'purchaser')
                buildBatchCostLine(theme, 'Freight & Transport (Purchaser Paid)', transport),
              const Divider(height: 20),
              buildBatchCostLine(theme, 'Total Purchaser Outlay (Bill Basis)', owed, bold: true),
              buildBatchCostLine(theme, 'Already Settled for this Batch', settledForBatch),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: remaining > 0 ? AppColors.roseSurface : AppColors.emeraldSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: remaining > 0 ? AppColors.rose.withValues(alpha: 0.25) : AppColors.emerald.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding Bill Payable',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: remaining > 0 ? AppColors.rose : AppColors.emeraldDark,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(remaining),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: remaining > 0 ? AppColors.rose : AppColors.emeraldDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (context.read<AuthProvider>().capabilities.can(Capability.createSettlement) &&
                  sellerId != null &&
                  remaining > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => showSettleSellerDialog(
                      context,
                      batch: batch,
                      sellerId: sellerId!,
                      sellerName: sellerName,
                      remaining: remaining,
                      settledForBatch: settledForBatch,
                    ),
                    icon: const Icon(HeroIcons.banknotes, size: 20),
                    label: Text(
                      'Settle Seller Payment',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
