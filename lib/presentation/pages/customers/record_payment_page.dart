import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/date_picker_field.dart';

class RecordPaymentPage extends ConsumerStatefulWidget {
  final String customerId;
  const RecordPaymentPage({super.key, required this.customerId});

  @override
  ConsumerState<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends ConsumerState<RecordPaymentPage> {
  final _amountController = TextEditingController();
  final _bankRefController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMode = 'cash';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _bankRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final authState = ref.read(authProvider);
    final businessId = authState.user?.id ?? '';

    final request = PaymentCreateRequest(
      businessId: businessId,
      amount: amount,
      paymentMode: _paymentMode,
      bankReference: _bankRefController.text.isNotEmpty ? _bankRefController.text : null,
      paymentDate: DateFormatter.toISO(_date),
      receivedBy: authState.user?.id,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final repo = ref.read(customerRepositoryProvider);
    await repo.recordPayment(widget.customerId, request);
    ref.invalidate(customerLedgerProvider(widget.customerId));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer ID:', style: TextStyle(color: Colors.grey)),
            Text(widget.customerId, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (PKR) *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _paymentMode == 'cash',
                  onSelected: (_) => setState(() => _paymentMode = 'cash'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bank Transfer'),
                  selected: _paymentMode == 'bank_transfer',
                  onSelected: (_) => setState(() => _paymentMode = 'bank_transfer'),
                ),
              ],
            ),
            if (_paymentMode == 'bank_transfer') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _bankRefController,
                decoration: const InputDecoration(labelText: 'Bank Reference'),
              ),
            ],
            const SizedBox(height: 16),
            DatePickerField(
              selectedDate: _date,
              onDateSelected: (d) => setState(() => _date = d),
              label: 'Payment Date',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
