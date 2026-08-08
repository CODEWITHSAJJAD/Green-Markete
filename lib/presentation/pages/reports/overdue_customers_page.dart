import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/green_card.dart';
import '../customers/customer_ledger_page.dart';

class OverdueCustomersPage extends StatefulWidget {
  const OverdueCustomersPage({super.key});

  @override
  State<OverdueCustomersPage> createState() => _OverdueCustomersPageState();
}

class _OverdueCustomersPageState extends State<OverdueCustomersPage> {
  double _threshold = 50000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<ReportProvider>().loadOverdue(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Overdue Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Threshold: ${CurrencyFormatter.format(_threshold)}', style: theme.textTheme.titleSmall),
                Slider(
                  value: _threshold,
                  min: 5000,
                  max: 500000,
                  divisions: 20,
                  label: CurrencyFormatter.format(_threshold),
                  onChanged: (v) => setState(() => _threshold = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: report.error != null
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
                    : _buildList(theme, report.overdue, businessId),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme, List<CreditReportModel> customers, String businessId) {
    final filtered = customers.where((c) => c.outstandingBalance >= _threshold).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('No overdue customers at this threshold.'));
    }
    return ListView.builder(
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
              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
              child: Icon(MingCuteIcons.mgc_alert_line, color: theme.colorScheme.secondary),
            ),
            title: Text(c.fullName),
            subtitle: Text(c.city ?? '-'),
            trailing: Text(
              CurrencyFormatter.format(c.outstandingBalance),
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            onTap: () {
              final cust = CustomerModel(
                id: c.id,
                businessId: businessId,
                fullName: c.fullName,
                phone: c.phone,
                city: c.city,
                outstandingBalance: c.outstandingBalance,
              );
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CustomerLedgerPage(customer: cust)),
              );
            },
          ),
        );
      },
    );
  }
}
