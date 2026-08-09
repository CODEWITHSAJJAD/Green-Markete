import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PartnerSettlementPage extends StatefulWidget {
  const PartnerSettlementPage({super.key});

  @override
  State<PartnerSettlementPage> createState() => _PartnerSettlementPageState();
}

class _PartnerSettlementPageState extends State<PartnerSettlementPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _fromPartnerId;
  String? _toPartnerId;
  String _paymentMode = 'cash';
  String _transactionType = 'settlement';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty)
        context.read<PartnerProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final partnerProvider = context.watch<PartnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Record Settlement')),
      body: partnerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : partnerProvider.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(partnerProvider.error.toString()),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.read<PartnerProvider>().load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(_fromPartnerId),
                    decoration: const InputDecoration(
                      labelText: 'From Partner',
                    ),
                    items: partnerProvider.partners
                        .map(
                          (p) => DropdownItem(
                            value: p.id,
                            child: Text(p.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _fromPartnerId = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(_toPartnerId),
                    decoration: const InputDecoration(labelText: 'To Partner'),
                    items: partnerProvider.partners
                        .map(
                          (p) => DropdownItem(
                            value: p.id,
                            child: Text(p.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _toPartnerId = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    validator: (value) =>
                        Validators.positiveNumber(value, 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(_transactionType),
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type',
                    ),
                    items: const [
                      DropdownItem(
                        value: 'settlement',
                        child: Text('Settlement'),
                      ),
                      DropdownItem(value: 'advance', child: Text('Advance')),
                      DropdownItem(
                        value: 'expense_reimbursement',
                        child: Text('Expense Reimbursement'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _transactionType = value ?? 'settlement',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    valueListenable: ValueNotifier(_paymentMode),
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                    ),
                    items: const [
                      DropdownItem(value: 'cash', child: Text('Cash')),
                      DropdownItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _paymentMode = value ?? 'cash'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referenceCtrl,
                    decoration: const InputDecoration(labelText: 'Reference'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final txProvider = context
                                .read<TransactionProvider>();
                            setState(() => _isSaving = true);
                            final transaction = await txProvider.create(
                              TransactionCreateRequest(
                                businessId: businessId,
                                fromPartnerId: _fromPartnerId!,
                                toPartnerId: _toPartnerId!,
                                amount: double.parse(_amountCtrl.text.trim()),
                                transactionType: _transactionType,
                                paymentMode: _paymentMode,
                                reference: _referenceCtrl.text.trim().isEmpty
                                    ? null
                                    : _referenceCtrl.text.trim(),
                                transactionDate: DateTime.now()
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                                notes: _notesCtrl.text.trim().isEmpty
                                    ? null
                                    : _notesCtrl.text.trim(),
                              ),
                            );
                            if (!mounted) return;
                            final errorText =
                                txProvider.error ?? 'Unknown error';
                            setState(() => _isSaving = false);
                            if (transaction != null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Settlement recorded'),
                                ),
                              );
                              navigator.pop();
                            } else {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed: $errorText')),
                              );
                            }
                          },
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Save Settlement'),
                  ),
                ],
              ),
            ),
    );
  }
}
