import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';

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
              bankReference: _referenceCtrl.text.trim().isEmpty ? null : _referenceCtrl.text.trim(),
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
          SnackBar(content: Text(err?.toString() ?? 'Failed to record payment')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMode,
                decoration: const InputDecoration(labelText: 'Payment mode'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank transfer')),
                ],
                onChanged: (value) => setState(() => _paymentMode = value ?? 'cash'),
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
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
