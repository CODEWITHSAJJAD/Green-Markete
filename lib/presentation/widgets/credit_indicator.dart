import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

class CreditIndicator extends StatelessWidget {
  const CreditIndicator({
    super.key,
    required this.totalPurchased,
    required this.totalPaid,
  });

  final double totalPurchased;
  final double totalPaid;

  double get paidRatio => totalPurchased > 0 ? (totalPaid / totalPurchased).clamp(0, 1) : 1;

  @override
  Widget build(BuildContext context) {
    final color = paidRatio >= 1 ? AppColors.success : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: paidRatio,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          paidRatio >= 1 ? 'Fully paid' : '${(paidRatio * 100).toStringAsFixed(0)}% paid',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
