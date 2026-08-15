import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../data/models/batch_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
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

    final purchaseCost = pl?.costBreakdown.purchaseCost ??
        batch.totalPurchaseCost;
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
    final transportInBill =
        batch.transportPaidBy == 'purchaser' ? transport : 0.0;
    final owed =
        purchaseCost +
        purchaserDaily +
        purchaserExpenses +
        packingCost +
        transportInBill;
    final remaining = (owed - settledForBatch)
        .clamp(0, double.infinity)
        .toDouble();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      MingCuteIcons.mgc_user_3_line,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seller / Receiving Partner', style: theme.textTheme.bodySmall),
                        Text(
                          sellerName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildBatchCostLine(theme, 'Purchase cost', purchaseCost),
              buildBatchCostLine(theme, 'Purchaser expenses', purchaserExpenses),
              buildBatchCostLine(theme, 'Purchaser daily charges', purchaserDaily),
              buildBatchCostLine(theme, 'Packing cost', packingCost),
              if (batch.transportPaidBy == 'purchaser')
                buildBatchCostLine(theme, 'Transport (purchaser-paid)', transport),
              const Divider(height: 20),
              buildBatchCostLine(theme, 'Bill owed to seller', owed, bold: true),
              buildBatchCostLine(theme, 'Settled for this batch', settledForBatch),
              buildBatchCostLine(theme, 'Remaining', remaining, bold: true),
              if (remaining > 0 &&
                  sellerId != null &&
                  context.read<AuthProvider>().capabilities.can(
                        Capability.createSettlement,
                      )) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => showSettleSellerDialog(
                      context,
                      batch: batch,
                      sellerId: sellerId!,
                      sellerName: sellerName,
                      remaining: remaining,
                      settledForBatch: settledForBatch,
                    ),
                    icon: const Icon(MingCuteIcons.mgc_wallet_3_line),
                    label: const Text('Settle Seller'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The bill owed to the seller is the purchaser-side total (purchase cost + purchaser expenses + daily charges + packing + purchaser-paid transport). Settle it fully or in partial splits — each payment is recorded as a partner transaction and matched to this batch via its code in the notes.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
