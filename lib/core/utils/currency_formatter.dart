import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _format = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    if (amount < 0) {
      return '-${_format.format(-amount)}';
    }
    return _format.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return 'PKR ${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return 'PKR ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
