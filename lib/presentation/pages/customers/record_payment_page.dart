import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/green_card.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class RecordPaymentPage extends StatefulWidget {
  final CustomerModel customer;

  const RecordPaymentPage({super.key, required this.customer});

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount must be positive')));
      return;
    }
    if (amount > widget.customer.outstandingBalance + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds outstanding balance of ${CurrencyFormatter.format(widget.customer.outstandingBalance)}',
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
      final ok = await context.read<CustomerProvider>().recordPayment(
        widget.customer.id,
        PaymentCreateRequest(
          customerId: widget.customer.id,
          businessId: businessId,
          amount: double.parse(_amountCtrl.text.trim()),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        final err = context.read<CustomerProvider>().error;
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
    final outstanding = widget.customer.outstandingBalance;
    final overLimit = amount > outstanding + 0.01;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GreenCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (outstanding > 0
                                    ? AppColors.error
                                    : AppColors.success)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        outstanding > 0
                            ? MingCuteIcons.mgc_wallet_3_line
                            : MingCuteIcons.mgc_check_circle_fill,
                        color: outstanding > 0
                            ? AppColors.error
                            : AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  if (v > outstanding + 0.01)
                    return 'Exceeds outstanding balance';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField2<String>(
                isExpanded: true,
                valueListenable: ValueNotifier(_paymentMode),
                decoration: const InputDecoration(labelText: 'Payment mode'),
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
