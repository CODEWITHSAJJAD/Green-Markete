import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  final double amount;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      CurrencyFormatter.format(amount),
      style: TextStyle(
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color ?? (amount < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
