import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_writer.dart';

/// Writes [csv] to a temp file with the given [fileName] and opens the
/// system share sheet so the user can send it via email / WhatsApp / Drive.
Future<void> shareCsv({
  required String csv,
  required String fileName,
  String? subject,
}) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$fileName';
  final file = File(path);
  await file.writeAsString(csv);
  await Share.shareXFiles(
    [XFile(path, mimeType: 'text/csv', name: fileName)],
    subject: subject,
  );
}

/// Convenience: build CSV from rows + columns then share.
Future<void> exportAndShareCsv({
  required List<String> columns,
  required List<List<Object?>> rows,
  required String fileName,
  String? subject,
}) async {
  final csv = buildCsv(columns: columns, rows: rows);
  await shareCsv(csv: csv, fileName: fileName, subject: subject);
}