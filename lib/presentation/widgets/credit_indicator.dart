import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

class CreditIndicator extends StatelessWidget {
  final double totalPurchased;
  final double totalPaid;

  const CreditIndicator({
    super.key,
    required this.totalPurchased,
    required this.totalPaid,
  });

  double get paidRatio => totalPurchased > 0 ? (totalPaid / totalPurchased).clamp(0, 1) : 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: paidRatio,
            minHeight: 8,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              paidRatio >= 1 ? AppColors.success : AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(paidRatio * 100).toStringAsFixed(0)}% paid',
          style: TextStyle(
            fontSize: 12,
            color: paidRatio >= 1 ? AppColors.success : AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
