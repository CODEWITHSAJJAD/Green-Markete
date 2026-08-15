import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _format = NumberFormat('#,##0', 'en_US');

  /// Active currency code (e.g. 'PKR', 'USD'). Set by [BusinessProvider] when
  /// the active business loads; defaults to PKR.
  static String currentCode = 'PKR';

  /// Currency symbols for known codes. Falls back to the code itself when no
  /// symbol is known.
  static const Map<String, String> _symbols = {
    'PKR': 'Rs',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'AED': 'د.إ',
    'SAR': 'SAR',
    'CNY': '¥',
  };

  static String _symbol() => _symbols[currentCode] ?? currentCode;

  static String format(num? amount, {String? code}) {
    final symbol = code != null
        ? (_symbols[code] ?? code)
        : _symbol();
    if (amount == null) return '$symbol 0';
    return '$symbol ${_format.format(amount)}';
  }

  static String formatCompact(num? amount, {String? code}) {
    final symbol = code != null
        ? (_symbols[code] ?? code)
        : _symbol();
    if (amount == null) return '$symbol 0';
    if (amount >= 10000000) return '$symbol ${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '$symbol ${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '$symbol ${(amount / 1000).toStringAsFixed(1)}K';
    return '$symbol ${_format.format(amount)}';
  }

  static String formatShort(num? amount) {
    if (amount == null) return '0';
    return _format.format(amount);
  }
}
