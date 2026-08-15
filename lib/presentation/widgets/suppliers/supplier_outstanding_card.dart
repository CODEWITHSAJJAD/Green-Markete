import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../green_card.dart';

class SupplierOutstandingCard extends StatelessWidget {
  final SupplierOutstanding supplier;
  final VoidCallback onTap;

  const SupplierOutstandingCard({
    super.key,
    required this.supplier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = supplier;
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: s.outstanding > 0
                ? AppColors.error.withValues(alpha: 0.12)
                : AppColors.success.withValues(alpha: 0.12),
            child: Icon(
              s.outstanding > 0
                  ? MingCuteIcons.mgc_time_line
                  : MingCuteIcons.mgc_check_circle_fill,
              color: s.outstanding > 0 ? AppColors.error : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.supplierName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Due ${CurrencyFormatter.format(s.totalDue)} · Paid ${CurrencyFormatter.format(s.totalPaid)}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(s.outstanding),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: s.outstanding > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                s.outstanding > 0 ? 'Outstanding' : 'Settled',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
