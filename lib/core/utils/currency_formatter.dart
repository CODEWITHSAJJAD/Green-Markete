import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _format = NumberFormat('#,##0', 'en_US');

  static String format(num? amount) {
    if (amount == null) return 'PKR 0';
    return 'PKR ${_format.format(amount)}';
  }

  static String formatCompact(num? amount) {
    if (amount == null) return 'PKR 0';
    if (amount >= 10000000) return 'PKR ${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return 'PKR ${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return 'PKR ${(amount / 1000).toStringAsFixed(1)}K';
    return 'PKR ${_format.format(amount)}';
  }

  static String formatShort(num? amount) {
    if (amount == null) return '0';
    return _format.format(amount);
  }
}
