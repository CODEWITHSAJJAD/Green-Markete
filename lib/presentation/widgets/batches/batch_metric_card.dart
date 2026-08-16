import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';

Widget buildBatchMetric(ThemeData theme, String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppColors.divider,
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

Widget buildBatchCostLine(
  ThemeData theme,
  String title,
  double value, {
  bool bold = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          CurrencyFormatter.format(value),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

IconData getPaymentModeIcon(String mode) {
  switch (mode.toLowerCase()) {
    case 'cash':
      return HeroIcons.banknotes;
    case 'credit':
      return HeroIcons.credit_card;
    case 'part_credit':
      return HeroIcons.wallet;
    default:
      return HeroIcons.banknotes;
  }
}

Color getPaymentModeColor(ThemeData theme, String mode) {
  switch (mode.toLowerCase()) {
    case 'cash':
      return AppColors.emerald;
    case 'credit':
      return AppColors.rose;
    case 'part_credit':
      return AppColors.amber;
    default:
      return AppColors.primary;
  }
}
