import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const AmountText({
    super.key,
    required this.amount,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyFormatter.format(amount),
      style: TextStyle(
        fontFamily: 'Roboto Mono',
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? (amount < 0 ? Colors.red.shade700 : null),
      ),
    );
  }
}
