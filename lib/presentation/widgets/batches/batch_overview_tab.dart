import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../status_pill.dart';
import '../status_timeline.dart';
import 'batch_dialogs.dart';
import 'batch_metric_card.dart';

class BatchOverviewTab extends StatelessWidget {
  final BatchModel batch;

  const BatchOverviewTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch.status == 'closed')
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(HeroIcons.lock_closed, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Closed — Read only. Edits, packing, expenses, and sales are locked.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.productName ?? 'Produce Batch',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch Code: #${batch.batchCode}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(status: batch.status),
                ],
              ),
              const SizedBox(height: 18),
              StatusTimeline(currentStatus: batch.status),
              const SizedBox(height: 18),
              _buildQuantityProgress(context, batch),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  buildBatchMetric(
                    theme,
                    'Purchase Cost',
                    CurrencyFormatter.format(batch.totalPurchaseCost),
                  ),
                  buildBatchMetric(
                    theme,
                    'Price / Unit',
                    CurrencyFormatter.format(batch.purchasePricePerUnit),
                  ),
                  buildBatchMetric(
                    theme,
                    'Transport Paid By',
                    batch.transportPaidBy?.toUpperCase() ?? 'NONE',
                  ),
                ],
              ),
              if (batch.supplierName != null && batch.supplierName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(HeroIcons.building_storefront, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Supplier Origin: ${batch.supplierName}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (batch.purchasePaymentMode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(HeroIcons.credit_card, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _purchasePaymentSummary(batch),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (batch.status != 'closed') ...[
                if (batch.status == 'delivered' &&
                    !context.read<AuthProvider>().canEditSellerSide &&
                    !context.read<AuthProvider>().capabilities.isOwner) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          HeroIcons.truck,
                          size: 18,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Batch safely delivered. Awaiting seller in market to start selling.',
                            style: GoogleFonts.inter(
                              color: AppColors.emeraldDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (context.read<AuthProvider>().capabilities.can(Capability.editBatch)) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => advanceBatchStatus(context, batch.id, batch.status),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(HeroIcons.arrow_right_circle, size: 20),
                      label: Text(
                        _nextStatusButtonLabel(batch.status),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _nextStatusButtonLabel(String currentStatus) {
    final idx = batchStatusFlow.indexOf(currentStatus);
    if (idx < 0 || idx >= batchStatusFlow.length - 1) return 'Advance Status';
    final next = batchStatusFlow[idx + 1];
    return switch (next) {
      'packed' => 'Mark as Packed',
      'in_transit' => 'Dispatch (In Transit)',
      'delivered' => 'Mark as Delivered',
      'selling' => 'Start Selling in Market',
      'closed' => 'Close Batch',
      _ => 'Advance to ${next.replaceAll('_', ' ')}',
    };
  }

  Widget _buildQuantityProgress(BuildContext context, BatchModel batch) {
    final sold = context.watch<SaleProvider>().sales.fold<double>(
      0,
      (acc, s) => acc + s.quantitySold,
    );
    final total = batch.totalQuantity;
    final remaining = (total - sold).clamp(0, total).toDouble();
    final pct = total > 0 ? (sold / total).clamp(0, 1).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sales vs Inventory Remaining',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}% Sold',
                style: GoogleFonts.plusJakartaSans(
                  color: pct >= 1 ? AppColors.emerald : AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: buildBatchMetric(
                  Theme.of(context),
                  'Sold Out',
                  '${sold.toStringAsFixed(sold.truncateToDouble() == sold ? 0 : 1)} ${batch.quantityUnit}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBatchMetric(
                  Theme.of(context),
                  'Remaining Stock',
                  '${remaining.toStringAsFixed(remaining.truncateToDouble() == remaining ? 0 : 1)} ${batch.quantityUnit}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              color: pct >= 1 ? AppColors.emerald : AppColors.primary,
              backgroundColor: AppColors.surfaceAlt,
            ),
          ),
        ],
      ),
    );
  }

  String _purchasePaymentSummary(BatchModel batch) {
    final mode = batch.purchasePaymentMode ?? 'cash';
    final label = switch (mode) {
      'credit' => 'Procurement on Credit',
      'part_credit' => 'Part Cash / Part Credit',
      _ => 'Paid in Cash',
    };
    final remaining = (batch.totalPurchaseCost - batch.purchaseAmountPaid)
        .clamp(0, double.infinity);
    if (batch.purchaseAmountPaid > 0) {
      return '$label — Paid ${CurrencyFormatter.format(batch.purchaseAmountPaid)}, '
          'Balance: ${CurrencyFormatter.format(remaining)}';
    }
    if (mode == 'credit') {
      return '$label — Full ${CurrencyFormatter.format(remaining)} Outstanding';
    }
    return label;
  }
}
