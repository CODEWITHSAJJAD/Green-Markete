import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import '../../../core/utils/currency_formatter.dart';

Widget buildBatchMetric(ThemeData theme, String label, String value) {
  return Container(
    width: 155,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.08),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleSmall),
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
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    ),
  );
}

IconData getPaymentModeIcon(String mode) {
  switch (mode) {
    case 'cash':
      return MingCuteIcons.mgc_wallet_3_line;
    case 'credit':
      return MingCuteIcons.mgc_time_line;
    case 'bank_transfer':
      return MingCuteIcons.mgc_bank_line;
    case 'partial_credit':
      return MingCuteIcons.mgc_chart_pie_line;
    default:
      return MingCuteIcons.mgc_bill_line;
  }
}

Color getPaymentModeColor(ThemeData theme, String mode) {
  switch (mode) {
    case 'cash':
      return theme.colorScheme.primary;
    case 'credit':
      return theme.colorScheme.error;
    case 'bank_transfer':
      return Colors.blue;
    case 'partial_credit':
      return theme.colorScheme.secondary;
    default:
      return theme.colorScheme.outline;
  }
}
