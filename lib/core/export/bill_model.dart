/// Generic bill document model.
///
/// A single [BillModel] can be rendered as a formatted widget (image), a PDF,
/// or flattened to CSV, so every screen shares one definition of "the bill".
class BillHeaderLine {
  final String label;
  final String value;

  const BillHeaderLine(this.label, this.value);
}

class BillLine {
  final String label;
  final String value;
  final String? detail;
  final bool emphasize;

  const BillLine(this.label, this.value, {this.detail, this.emphasize = false});
}

class BillSection {
  final String title;
  final List<BillLine> lines;

  const BillSection(this.title, this.lines);
}

class BillModel {
  /// e.g. 'Batch Bill', 'Customer Credit Statement', 'P&L Summary'.
  final String documentTitle;

  /// e.g. the business name, shown under the title.
  final String? businessName;

  /// Key/value lines shown at the top (customer, date, batch, phone...).
  final List<BillHeaderLine> header;

  final List<BillSection> sections;

  /// The highlighted bottom line (net profit, total outstanding...).
  final BillLine? total;

  /// Optional closing note / disclaimer.
  final String? footer;

  const BillModel({
    required this.documentTitle,
    this.businessName,
    this.header = const [],
    this.sections = const [],
    this.total,
    this.footer,
  });
}
