import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../../core/utils/currency_formatter.dart';

class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.label,
    required this.value,
    this.isProfit = true,
  });

  final String label;
  final double value;
  final bool isProfit;

  @override
  Widget build(BuildContext context) {
    final color = value == 0
        ? AppColors.textSecondary
        : isProfit
            ? AppColors.success
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${CurrencyFormatter.formatShort(value)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
