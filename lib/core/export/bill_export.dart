import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'bill_model.dart';
import 'bill_view.dart';
import 'csv_writer.dart';

/// Shows the share-format chooser (PDF / CSV / Image) and runs the export.
Future<void> shareBill(
  BuildContext context, {
  required BillModel bill,
  required String fileName,
  String? subject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Share bill as',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF'),
            subtitle: const Text('Print-ready document'),
            onTap: () {
              Navigator.pop(sheetCtx);
              _sharePdf(context, bill, fileName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('CSV'),
            subtitle: const Text('Spreadsheet-compatible data'),
            onTap: () {
              Navigator.pop(sheetCtx);
              _shareCsv(context, bill, fileName, subject);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Image'),
            subtitle: const Text('Share as a bill photo'),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BillImagePage(bill: bill, fileName: fileName, subject: subject),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Flattens a bill into CSV rows (document title, header lines, sections, total).
String billToCsv(BillModel bill) {
  final rows = <List<Object?>>[
    [bill.documentTitle],
    if (bill.businessName != null && bill.businessName!.isNotEmpty) [bill.businessName!],
    ...bill.header.map((h) => [h.label, h.value]),
    if (bill.header.isNotEmpty) const [],
    for (final section in bill.sections) ...[
      [section.title],
      ...section.lines.map((l) => [l.label, l.value, if (l.detail != null && l.detail!.isNotEmpty) l.detail]),
      const [],
    ],
    if (bill.total != null) [bill.total!.label, bill.total!.value],
    if (bill.footer != null && bill.footer!.isNotEmpty) [bill.footer!],
  ];
  return buildCsv(columns: const ['Label', 'Value', 'Detail'], rows: rows);
}

Future<void> _shareCsv(
  BuildContext context,
  BillModel bill,
  String fileName,
  String? subject,
) async {
  try {
    final csv = billToCsv(bill);
    final dir = await getTemporaryDirectory();
    final safeName = _baseName(fileName);
    final file = File('${dir.path}/$safeName.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: '$safeName.csv')],
      subject: subject,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to export CSV: $e')),
    );
  }
}

Future<void> _sharePdf(
  BuildContext context,
  BillModel bill,
  String fileName,
) async {
  try {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text(
                bill.documentTitle,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
        build: (_) => _pdfContent(bill),
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: _baseName(fileName));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to export PDF: $e')),
    );
  }
}

List<pw.Widget> _pdfContent(BillModel bill) {
  const green = PdfColors.green800;
  return [
      pw.Center(
        child: pw.Text(
          'MANDI ROZNAMCHA',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 3,
            color: green,
          ),
        ),
      ),
      pw.SizedBox(height: 14),
      pw.Center(
        child: pw.Text(
          bill.documentTitle,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
      ),
      if (bill.businessName != null && bill.businessName!.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            bill.businessName!,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
      ],
      pw.SizedBox(height: 12),
      pw.Container(height: 1, color: PdfColors.green200),
      pw.SizedBox(height: 10),
      for (final line in bill.header)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  line.label,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Text(
                line.value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ],
          ),
        ),
      pw.SizedBox(height: 10),
      pw.Container(height: 1, color: PdfColors.green200),
      pw.SizedBox(height: 10),
      for (final section in bill.sections) ...[
        pw.Text(
          section.title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 5),
        for (final line in section.lines) _pdfLine(line),
        pw.SizedBox(height: 8),
      ],
      if (bill.total != null) ...[
        pw.Container(height: 1.5, color: green),
        pw.SizedBox(height: 6),
        _pdfLine(bill.total!, strong: true),
        pw.SizedBox(height: 6),
        pw.Container(height: 1.5, color: green),
      ],
      if (bill.footer != null && bill.footer!.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        pw.Center(
          child: pw.Text(
            bill.footer!,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ],
  ];
}

pw.Widget _pdfLine(BillLine line, {bool strong = false}) {
  final emphasized = strong || line.emphasize;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            line.label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey900,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          line.value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.bold,
            color: emphasized ? PdfColors.green900 : PdfColors.grey900,
          ),
        ),
      ],
    ),
  );
}

/// Page that previews the bill and captures it to a PNG for sharing.
class BillImagePage extends StatefulWidget {
  final BillModel bill;
  final String fileName;
  final String? subject;

  const BillImagePage({
    super.key,
    required this.bill,
    required this.fileName,
    this.subject,
  });

  @override
  State<BillImagePage> createState() => _BillImagePageState();
}

class _BillImagePageState extends State<BillImagePage> {
  final _boundaryKey = GlobalKey();
  bool _capturing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill preview'),
        actions: [
          IconButton(
            tooltip: 'Share as image',
            onPressed: _capturing ? null : _share,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RepaintBoundary(
            key: _boundaryKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: BillView(bill: widget.bill),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _capturing = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw Exception('Could not encode image');
        }
        final bytes = byteData.buffer.asUint8List();
        final dir = await getTemporaryDirectory();
        final name = _baseName(widget.fileName);
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png', name: '$name.png')],
          subject: widget.subject,
        );
      } finally {
        image.dispose();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share image: $e')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }
}

/// Strips a trailing .pdf/.csv extension and any path-hostile characters.
String _baseName(String fileName) {
  final stripped = fileName.replaceAll(RegExp(r'\.(pdf|csv)$', caseSensitive: false), '');
  return stripped.replaceAll(RegExp(r'[^\w\-.]+'), '_');
}
