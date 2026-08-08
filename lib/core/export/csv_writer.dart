/// Builds CSV text from a list of rows and column definitions, with proper
/// escaping (commas, quotes, newlines).
String buildCsv({
  required List<String> columns,
  required List<List<Object?>> rows,
}) {
  final buf = StringBuffer();
  buf.writeln(columns.map(_escape).join(','));
  for (final row in rows) {
    buf.writeln(row.map(_escape).join(','));
  }
  return buf.toString();
}

String _escape(Object? value) {
  if (value == null) return '';
  final raw = value.toString();
  var s = raw;
  if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
    s = '"${s.replaceAll('"', '""')}"';
  }
  return s;
}