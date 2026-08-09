import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/export/bill_export.dart';
import '../../../core/export/bill_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/green_card.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
            icon: const Icon(MingCuteIcons.mgc_share_2_line),
            tooltip: 'Share report',
            onPressed: () => _shareReport(businessId),
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
    final cities =
        customers.map((c) => c.city).whereType<String>().toSet().toList()
          ..sort();
    final filtered = _cityFilter == null
        ? customers.toList()
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
                child: DropdownButtonFormField2<String?>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(_cityFilter),
                  decoration: const InputDecoration(
                    labelText: 'Filter by city',
                  ),
                  items: [
                    const DropdownItem<String?>(
                      value: null,
                      child: Text('All cities'),
                    ),
                    ...cities.map(
                      (c) => DropdownItem<String?>(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _cityFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField2<String>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(_sortKey),
                  decoration: const InputDecoration(labelText: 'Sort by'),
                  items: const [
                    DropdownItem(
                      value: 'outstanding',
                      child: Text('Outstanding (high â†’ low)'),
                    ),
                    DropdownItem(value: 'name', child: Text('Name (A â†’ Z)')),
                  ],
                  onChanged: (v) =>
                      setState(() => _sortKey = v ?? 'outstanding'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No customers match the filter.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return GreenCard(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.10,
                          ),
                          child: Text(
                            c.fullName.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Text(c.fullName),
                        subtitle: Text(
                          [c.city, c.phone]
                              .whereType<String>()
                              .where((e) => e.isNotEmpty)
                              .join('  â€¢  '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.format(c.outstandingBalance),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: c.outstandingBalance > 0
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Share statement',
                              icon: const Icon(
                                MingCuteIcons.mgc_share_2_line,
                                size: 20,
                              ),
                              onPressed: () => _shareCustomerStatement(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _shareReport(String businessId) async {
    final rows = context.read<ReportProvider>().credit;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No credit data to share')));
      return;
    }
    final businessName = context.read<BusinessProvider>().business?.name;
    var totalOutstanding = 0.0;
    for (final r in rows) {
      totalOutstanding += r.outstandingBalance;
    }
    final bill = BillModel(
      documentTitle: 'Customer Credit Report',
      businessName: businessName,
      header: [
        BillHeaderLine('Customers', '${rows.length}'),
        BillHeaderLine('Date', DateFormatter.toDDMMYYYY(DateTime.now())),
      ],
      sections: [
        BillSection('Outstanding Balances', [
          for (final r in rows)
            BillLine(
              r.fullName,
              CurrencyFormatter.format(r.outstandingBalance),
            ),
        ]),
      ],
      total: BillLine(
        'Total Outstanding',
        CurrencyFormatter.format(totalOutstanding),
        emphasize: true,
      ),
      footer:
          'Generated by Green Market on ${DateFormatter.toDDMMYYYY(DateTime.now())}. '
          'Amounts in ${CurrencyFormatter.currentCode}.',
    );
    await shareBill(
      context,
      bill: bill,
      fileName: 'credit_report',
      subject: 'Green Market â€” Credit Report',
    );
  }

  Future<void> _shareCustomerStatement(CreditReportModel c) async {
    final businessName = context.read<BusinessProvider>().business?.name;
    final bill = BillModel(
      documentTitle: 'Credit Statement',
      businessName: businessName,
      header: [
        BillHeaderLine('Customer', c.fullName),
        if (c.phone != null && c.phone!.isNotEmpty)
          BillHeaderLine('Phone', c.phone!),
        if (c.city != null && c.city!.isNotEmpty)
          BillHeaderLine('City', c.city!),
        BillHeaderLine('Date', DateFormatter.toDDMMYYYY(DateTime.now())),
      ],
      sections: [
        BillSection('Account Summary', [
          BillLine(
            'Amount due on credit sales',
            CurrencyFormatter.format(c.outstandingBalance),
          ),
        ]),
      ],
      total: BillLine(
        'Outstanding Balance',
        CurrencyFormatter.format(c.outstandingBalance),
        emphasize: true,
      ),
      footer:
          'Please settle the outstanding balance at your earliest convenience. '
          'Amounts in ${CurrencyFormatter.currentCode}.',
    );
    await shareBill(
      context,
      bill: bill,
      fileName: 'credit_statement_${c.fullName.replaceAll(' ', '_')}',
      subject: 'Green Market â€” Credit Statement',
    );
  }
}
