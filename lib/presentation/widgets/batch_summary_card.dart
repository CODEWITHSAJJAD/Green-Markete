import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../core/config/theme.dart';
import '../../core/utils/currency_formatter.dart';
import 'green_card.dart';
import 'status_pill.dart';

class BatchSummaryCard extends StatelessWidget {
  const BatchSummaryCard({
    super.key,
    required this.productName,
    this.batchCode,
    required this.sourceCity,
    required this.destinationCity,
    required this.status,
    required this.quantity,
    required this.totalCost,
    required this.totalRevenue,
    required this.netProfitLoss,
  });

  final String productName;
  final String? batchCode;
  final String sourceCity;
  final String destinationCity;
  final String status;
  final String quantity;
  final double totalCost;
  final double totalRevenue;
  final double netProfitLoss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GreenCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: theme.textTheme.titleLarge),
                    if (batchCode != null) ...[
                      const SizedBox(height: 2),
                      Text(batchCode!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(MingCute.truck_line, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$sourceCity → $destinationCity', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text('Quantity: $quantity', style: theme.textTheme.bodySmall),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _metric(theme, 'Cost', CurrencyFormatter.format(totalCost))),
              const SizedBox(width: 8),
              Expanded(child: _metric(theme, 'Revenue', CurrencyFormatter.format(totalRevenue))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                netProfitLoss >= 0 ? MingCute.trending_up_line : MingCute.trending_down_line,
                size: 16,
                color: netProfitLoss >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Net ${netProfitLoss >= 0 ? 'Profit' : 'Loss'} · ${CurrencyFormatter.format(netProfitLoss)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: netProfitLoss >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
