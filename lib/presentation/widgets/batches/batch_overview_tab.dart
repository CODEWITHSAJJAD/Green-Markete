import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
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
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch.status == 'closed')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        MingCuteIcons.mgc_lock_line,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Closed — read only. Edits, packing, expenses and sales are locked.',
                          style: theme.textTheme.labelMedium,
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
                          batch.productName ?? 'Batch',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          batch.batchCode,
                          style: theme.textTheme.bodyMedium,
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
              const SizedBox(height: 12),
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
                    'Transport',
                    batch.transportPaidBy ?? '-',
                  ),
                ],
              ),
              if (batch.supplierName != null &&
                  batch.supplierName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(MingCuteIcons.mgc_store_line, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Supplier: ${batch.supplierName}',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (batch.purchasePaymentMode != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(MingCuteIcons.mgc_wallet_3_line, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _purchasePaymentSummary(batch),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (batch.status != 'closed' &&
                  context.read<AuthProvider>().capabilities.can(
                        Capability.editBatch,
                      )) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        advanceBatchStatus(context, batch.id, batch.status),
                    icon: const Icon(MingCuteIcons.mgc_route_line),
                    label: const Text('Advance Status'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityProgress(BuildContext context, BatchModel batch) {
    final theme = Theme.of(context);
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sold vs Remaining',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: pct >= 1 ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Sold',
                  '${sold.toStringAsFixed(0)} ${batch.quantityUnit}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Remaining',
                  '${remaining.toStringAsFixed(0)} ${batch.quantityUnit}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              color: pct >= 1 ? AppColors.success : AppColors.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total ${total.toStringAsFixed(0)} ${batch.quantityUnit}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _purchasePaymentSummary(BatchModel batch) {
    final mode = batch.purchasePaymentMode ?? 'cash';
    final label = switch (mode) {
      'credit' => 'Purchase on credit',
      'part_credit' => 'Part cash / part credit',
      _ => 'Paid in cash',
    };
    final remaining = (batch.totalPurchaseCost - batch.purchaseAmountPaid)
        .clamp(0, double.infinity);
    if (batch.purchaseAmountPaid > 0) {
      return '$label — paid ${CurrencyFormatter.format(batch.purchaseAmountPaid)}, '
          'remaining ${CurrencyFormatter.format(remaining)}';
    }
    if (mode == 'credit') {
      return '$label — full ${CurrencyFormatter.format(remaining)} outstanding';
    }
    return label;
  }
}
