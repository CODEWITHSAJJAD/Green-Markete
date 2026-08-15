import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../green_card.dart';

class SupplierLedgerTile extends StatelessWidget {
  final SupplierLedgerEntry entry;

  const SupplierLedgerTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPayment = entry.type == 'payment';
    final batchCode = entry.batchCode;
    final paidAtPurchase = entry.paidAtPurchase;

    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isPayment
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.secondary.withValues(alpha: 0.12),
            child: Icon(
              isPayment
                  ? MingCuteIcons.mgc_arrow_down_line
                  : MingCuteIcons.mgc_arrow_up_line,
              color: isPayment
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.toDDMMYYYY(
                    DateTime.tryParse(entry.date) ?? DateTime(2000),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                if (batchCode != null && batchCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      batchCode,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (!isPayment) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Debt ${CurrencyFormatter.format(entry.amount)} · Paid ${CurrencyFormatter.format(paidAtPurchase)} · Remaining ${CurrencyFormatter.format((entry.amount - paidAtPurchase).clamp(0, double.infinity))}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(entry.amount),
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: ${CurrencyFormatter.format(entry.runningBalance.clamp(0, double.infinity))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: entry.runningBalance > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
