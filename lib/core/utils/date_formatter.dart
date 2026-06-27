import 'package:intl/intl.dart';

class DateFormatter {
  static final _ddmmyyyy = DateFormat('dd/MM/yyyy');
  static final _display = DateFormat('MMM dd, yyyy');
  static final _iso = DateFormat('yyyy-MM-dd');

  static String toDisplay(DateTime date) => _display.format(date);
  static String toDDMMYYYY(DateTime date) => _ddmmyyyy.format(date);
  static String toISO(DateTime date) => _iso.format(date);

  static DateTime? fromISO(String date) {
    try {
      return _iso.parse(date);
    } catch (_) {
      return null;
    }
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return toDisplay(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
