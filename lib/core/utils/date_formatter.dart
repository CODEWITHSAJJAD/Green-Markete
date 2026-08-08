import 'package:intl/intl.dart';

class DateFormatter {
  static final _displayFormat = DateFormat('dd/MM/yyyy');
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  static String display(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return _displayFormat.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String toISO(DateTime date) {
    return _isoFormat.format(date);
  }

  static String displayDateTime(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String toDDMMYYYY(DateTime date) => _displayFormat.format(date);

  static String toDisplay(DateTime date) => _displayFormat.format(date);

  static String relative(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}
