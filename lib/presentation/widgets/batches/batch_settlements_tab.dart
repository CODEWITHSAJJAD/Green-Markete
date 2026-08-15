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
    final pl = plProvider.pl;

    final batch = widget.batch;
    final batchPartners = detailProvider.batchPartners;
    final sellers = batchPartners
        .where((p) => p['role'] == 'seller' || p['role'] == 'both')
        .toList();
    if (sellers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No selling partner on this batch. Add a seller in the wizard to track settlements.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final sellerId = sellers.first['partner_id'] as String;
    final sellerName =
        partnerProvider.partners
            .where((p) => p.id == sellerId)
            .map((p) => p.fullName)
            .firstOrNull ??
        'Seller';

    if (_ledgerSellerId != sellerId) {
      _ledgerSellerId = sellerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<TransactionProvider>().loadLedger(sellerId);
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
        .where((t) => t.toPartnerId == sellerId)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final purchaseCost = pl?.costBreakdown.purchaseCost ?? 0;
    final purchaserDaily = pl?.costBreakdown.purchaserDailyCharges ?? 0;
    final purchaserExpenses = pl?.costBreakdown.purchaserExpenses ?? 0;
    final packingCost = pl?.costBreakdown.packingCost ?? 0;
    final transport = pl?.costBreakdown.transportCost ?? 0;
    final transportInBill = batch.transportPaidBy == 'purchaser' ? transport : 0;
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
              Text('Seller: $sellerName', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
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
                      sellerId: sellerId,
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
