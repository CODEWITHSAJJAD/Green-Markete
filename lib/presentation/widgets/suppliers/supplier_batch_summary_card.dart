import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../green_card.dart';

class SupplierBatchSummaryCard extends StatelessWidget {
  final String batchCode;
  final List<SupplierBatchSummary> lines;

  const SupplierBatchSummaryCard({
    super.key,
    required this.batchCode,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchaseDate = lines.first.purchaseDate;
    final debt = lines.fold<double>(0, (s, l) => s + l.debt);
    final paid = lines.fold<double>(0, (s, l) => s + l.paidAtPurchase);
    final remaining = lines.fold<double>(0, (s, l) => s + l.remaining);

    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                MingCuteIcons.mgc_inbox_2_line,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  batchCode,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                purchaseDate.isEmpty
                    ? ''
                    : DateFormatter.toDDMMYYYY(
                        DateTime.tryParse(purchaseDate) ?? DateTime(2000),
                      ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Debt ${CurrencyFormatter.format(debt)} · Paid ${CurrencyFormatter.format(paid)}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.format(remaining),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: remaining > 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.supplierName,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(l.remaining),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: l.remaining > 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
