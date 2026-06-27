import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class StatBadge extends StatelessWidget {
  final String label;
  final double value;
  final bool isProfit;

  const StatBadge({
    super.key,
    required this.label,
    required this.value,
    this.isProfit = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = value == 0
        ? AppColors.textSecondary
        : isProfit
            ? AppColors.success
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: PKR ${value.toStringAsFixed(0)}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
