import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/app_dropdown.dart';

class PartnerReportPage extends StatefulWidget {
  final String partnerId;

  const PartnerReportPage({super.key, required this.partnerId});

  @override
  State<PartnerReportPage> createState() => _PartnerReportPageState();
}

class _PartnerReportPageState extends State<PartnerReportPage> {
  String? _selectedBatchId;
  String? _loadedBatchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBatches());
  }

  void _loadBatches() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<BatchListProvider>().load(businessId);
  }

  void _loadPartnerPL(String batchId) {
    context.read<ReportProvider>().loadPartnerPL(widget.partnerId, batchId);
  }

  @override
  Widget build(BuildContext context) {
    final batchesProvider = context.watch<BatchListProvider>();
    final report = context.watch<ReportProvider>();

    final batches = batchesProvider.batches;
    final selectedBatchId =
        _selectedBatchId ?? (batches.isNotEmpty ? batches.first.id : null);

    if (selectedBatchId != null && selectedBatchId != _loadedBatchId) {
      _loadedBatchId = selectedBatchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedBatchId == selectedBatchId) {
          _loadPartnerPL(selectedBatchId);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Partner P&L')),
      body: batchesProvider.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(batchesProvider.error!),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadBatches,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : batchesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedBatchId == null
          ? const Center(child: Text('No batches available.'))
          : _buildContent(selectedBatchId, batches, report),
    );
  }

  Widget _buildContent(
    String selectedBatchId,
    List<BatchModel> batches,
    ReportProvider report,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppDropdown<String>.fromList(
          value: selectedBatchId,
          labelText: 'Select Batch',
          items: batches.map((b) => b.id).toList(),
          itemLabel: (id) {
            final batch = batches.firstWhere((b) => b.id == id);
            return batch.batchCode.isNotEmpty
                ? batch.batchCode
                : (batch.productName ?? batch.id);
          },
          onChanged: (value) {
            setState(() => _selectedBatchId = value);
            if (value != null) _loadPartnerPL(value);
          },
        ),
        const SizedBox(height: 20),
        if (report.error != null)
          Column(
            children: [
              Text(report.error!),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _loadPartnerPL(selectedBatchId),
                child: const Text('Retry'),
              ),
            ],
          )
        else if (report.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (report.partnerPL != null) ...[
          _tile('Daily Charges', report.partnerPL!.dailyCharges),
          _tile('Expenses Logged', report.partnerPL!.expensesLogged),
          _tile('Sales Made', report.partnerPL!.salesMade),
          _tile('Net Share', report.partnerPL!.netShare, highlight: true),
        ],
      ],
    );
  }

  Widget _tile(String title, double amount, {bool highlight = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            color: highlight ? (amount >= 0 ? Colors.green : Colors.red) : null,
          ),
        ),
      ),
    );
  }
}
