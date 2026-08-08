import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/export/csv_export.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/green_card.dart';

class PLReportPage extends StatefulWidget {
  const PLReportPage({super.key});

  @override
  State<PLReportPage> createState() => _PLReportPageState();
}

class _PLReportPageState extends State<PLReportPage> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<ReportProvider>().loadPLSummary(
      businessId,
      dateFrom: _from != null ? DateFormat('yyyy-MM-dd').format(_from!) : null,
      dateTo: _to != null ? DateFormat('yyyy-MM-dd').format(_to!) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final report = context.watch<ReportProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('P&L Summary'),
        actions: [
          IconButton(
            icon: const Icon(MingCuteIcons.mgc_calendar_3_line),
            tooltip: 'Date range',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: (_from != null && _to != null)
                    ? DateTimeRange(start: _from!, end: _to!)
                    : null,
              );
              if (picked != null) {
                setState(() {
                  _from = picked.start;
                  _to = picked.end;
                });
                _load();
              }
            },
          ),
          IconButton(
            icon: const Icon(MingCuteIcons.mgc_download_2_line),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(businessId),
          ),
        ],
      ),
      body: report.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(report.error!),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : report.isLoading
              ? const Center(child: CircularProgressIndicator())
              : report.plSummary == null
                  ? const Center(child: Text('No data available.'))
                  : _buildContent(theme, report.plSummary!),
    );
  }

  Widget _buildContent(ThemeData theme, PLSummaryModel pl) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_from != null && _to != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text('From: ${DateFormat('yyyy-MM-dd').format(_from!)}'),
                  onDeleted: () {
                    setState(() => _from = null);
                    _load();
                  },
                ),
                Chip(
                  label: Text('To: ${DateFormat('yyyy-MM-dd').format(_to!)}'),
                  onDeleted: () {
                    setState(() => _to = null);
                    _load();
                  },
                ),
              ],
            ),
          ),
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx == 0) return const Text('Rev');
                      if (idx == 1) return const Text('Cost');
                      return const Text('P/L');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _group(0, pl.totalRevenue, theme.colorScheme.primary),
                _group(1, pl.totalCost, theme.colorScheme.secondary),
                _group(2, pl.totalProfitLoss, pl.totalProfitLoss >= 0 ? AppColors.profit : AppColors.error),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _tile(theme, 'Total Revenue', pl.totalRevenue),
        _tile(theme, 'Total Cost', pl.totalCost),
        _tile(theme, 'Net Profit / Loss', pl.totalProfitLoss, highlight: true),
        _textTile(theme, 'Batches Included', '${pl.totalBatches}'),
      ],
    );
  }

  Future<void> _exportCsv(String businessId) async {
    final pl = context.read<ReportProvider>().plSummary;
    if (pl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('P&L summary not ready yet')),
      );
      return;
    }
    await exportAndShareCsv(
      columns: const ['Batch Code', 'Cost (PKR)', 'Revenue (PKR)', 'Net (PKR)'],
      rows: [
        for (final b in pl.batchSummaries)
          [
            b.batchCode ?? '',
            b.costBreakdown.totalCost.toStringAsFixed(2),
            b.revenue.totalRevenue.toStringAsFixed(2),
            b.netProfitLoss.toStringAsFixed(2),
          ],
        [],
        ['TOTAL', pl.totalCost.toStringAsFixed(2), pl.totalRevenue.toStringAsFixed(2), pl.totalProfitLoss.toStringAsFixed(2)],
      ],
      fileName: 'pl_report.csv',
      subject: 'Green Market — P&L Report',
    );
  }

  BarChartGroupData _group(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 28, borderRadius: BorderRadius.circular(8))]);
  }

  Widget _tile(ThemeData theme, String title, double value, {bool highlight = false}) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(
            CurrencyFormatter.format(value),
            style: theme.textTheme.titleMedium?.copyWith(
              color: highlight ? (value >= 0 ? AppColors.profit : AppColors.error) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textTile(ThemeData theme, String title, String value) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value, style: theme.textTheme.titleMedium)],
      ),
    );
  }
}
