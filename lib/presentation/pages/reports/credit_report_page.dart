import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/export/csv_export.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/green_card.dart';

class CreditReportPage extends StatefulWidget {
  const CreditReportPage({super.key});

  @override
  State<CreditReportPage> createState() => _CreditReportPageState();
}

class _CreditReportPageState extends State<CreditReportPage> {
  String? _cityFilter;
  String _sortKey = 'outstanding';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<ReportProvider>().loadCredit(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final report = context.watch<ReportProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Credit'),
        actions: [
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
              : _buildContent(theme, report.credit),
    );
  }

  Widget _buildContent(ThemeData theme, List<CreditReportModel> customers) {
    final cities = customers
        .map((c) => c.city)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final filtered = _cityFilter == null
        ? customers
        : customers.where((c) => c.city == _cityFilter).toList();
    filtered.sort((a, b) {
      if (_sortKey == 'name') return a.fullName.compareTo(b.fullName);
      return b.outstandingBalance.compareTo(a.outstandingBalance);
    });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _cityFilter,
                  decoration: const InputDecoration(labelText: 'Filter by city'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All cities')),
                    ...cities.map((c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c),
                        )),
                  ],
                  onChanged: (v) => setState(() => _cityFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortKey,
                  decoration: const InputDecoration(labelText: 'Sort by'),
                  items: const [
                    DropdownMenuItem(value: 'outstanding', child: Text('Outstanding (high → low)')),
                    DropdownMenuItem(value: 'name', child: Text('Name (A → Z)')),
                  ],
                  onChanged: (v) => setState(() => _sortKey = v ?? 'outstanding'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No customers match the filter.', style: theme.textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return GreenCard(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                          child: Text(
                            c.fullName.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary),
                          ),
                        ),
                        title: Text(c.fullName),
                        subtitle: Text([c.city, c.phone].whereType<String>().where((e) => e.isNotEmpty).join('  •  ')),
                        trailing: Text(
                          CurrencyFormatter.format(c.outstandingBalance),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: c.outstandingBalance > 0 ? theme.colorScheme.secondary : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(String businessId) async {
    final rows = context.read<ReportProvider>().credit;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credit data to export')),
      );
      return;
    }
    await exportAndShareCsv(
      columns: const ['Customer', 'Phone', 'City', 'Outstanding Balance (PKR)'],
      rows: [
        for (final r in rows)
          [r.fullName, r.phone ?? '', r.city ?? '', r.outstandingBalance.toStringAsFixed(2)],
      ],
      fileName: 'credit_report.csv',
      subject: 'Green Market — Credit Report',
    );
  }
}
