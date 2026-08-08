import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../core/config/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/batch_model.dart';
import 'green_card.dart';
import 'status_pill.dart';

class RecentActivityList extends StatelessWidget {
  final List<BatchModel> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(MingCuteIcons.mgc_inbox_line, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No recent activity', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    return Column(
      children: activities.map((batch) {
        return GreenCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(MingCuteIcons.mgc_shopping_bag_2_line, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (batch.productName ?? batch.batchCode).isEmpty ? 'Batch' : batch.productName ?? batch.batchCode,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    StatusPill(status: batch.status),
                  ],
                ),
              ),
              Text(
                batch.totalAmount != null
                    ? CurrencyFormatter.format(batch.totalAmount)
                    : '${batch.totalQuantity.toStringAsFixed(0)} ${batch.quantityUnit}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
