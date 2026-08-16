import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_dropdown.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/supplier_payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/supplier_provider.dart';

class RecordSupplierPaymentPage extends StatefulWidget {
  final String supplierName;
  final double outstanding;

  const RecordSupplierPaymentPage({
    super.key,
    required this.supplierName,
    required this.outstanding,
  });

  @override
  State<RecordSupplierPaymentPage> createState() =>
      _RecordSupplierPaymentPageState();
}

class _RecordSupplierPaymentPageState extends State<RecordSupplierPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMode = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be positive')),
      );
      return;
    }
    if (amount > widget.outstanding + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds outstanding of ${CurrencyFormatter.format(widget.outstanding)}',
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final businessId = auth.businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    try {
      final ok = await context.read<SupplierProvider>().recordPayment(
        SupplierPaymentCreateRequest(
          businessId: businessId,
          supplierName: widget.supplierName,
          amount: amount,
          paymentMode: _paymentMode,
          bankReference: _referenceCtrl.text.trim().isEmpty
              ? null
              : _referenceCtrl.text.trim(),
          paymentDate: DateTime.now().toIso8601String().split('T').first,
          receivedBy: auth.user?.id,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      if (ok) {
        DataRefreshNotifier.instance.refresh(businessId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        final err = context.read<SupplierProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err?.toString() ?? 'Failed to record payment'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final outstanding = widget.outstanding;
    final overLimit = amount > outstanding + 0.01;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.supplierName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      outstanding > 0
                          ? 'Outstanding balance'
                          : 'No balance owed',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(outstanding),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: outstanding > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  helperText: outstanding > 0
                      ? 'Must not exceed ${CurrencyFormatter.format(outstanding)}'
                      : 'No balance owed',
                  errorText: overLimit ? 'Exceeds outstanding balance' : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  final v = double.tryParse(value.trim());
                  if (v == null || v <= 0) return 'Enter a positive number';
                  if (v > outstanding + 0.01) {
                    return 'Exceeds outstanding balance';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                value: _paymentMode,
                labelText: 'Payment mode',
                items: const [
                  DropdownItem(value: 'cash', child: Text('Cash')),
                  DropdownItem(
                    value: 'bank_transfer',
                    child: Text('Bank transfer'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMode = value ?? 'cash'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenceCtrl,
                decoration: const InputDecoration(labelText: 'Bank reference'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_saving || overLimit) ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}