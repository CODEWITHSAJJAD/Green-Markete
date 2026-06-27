import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../core/utils/date_formatter.dart';

class PartnerSettlementPage extends ConsumerStatefulWidget {
  const PartnerSettlementPage({super.key});

  @override
  ConsumerState<PartnerSettlementPage> createState() => _PartnerSettlementPageState();
}

class _PartnerSettlementPageState extends ConsumerState<PartnerSettlementPage> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMode = 'cash';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    final businessId = authState.user?.id ?? '';
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final request = TransactionCreateRequest(
      businessId: businessId,
      fromPartnerId: '',
      toPartnerId: '',
      amount: amount,
      transactionType: 'settlement',
      paymentMode: _paymentMode,
      reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      transactionDate: DateFormatter.toISO(_date),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final repo = ref.read(transactionRepositoryProvider);
    await repo.create(request);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Settlement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (PKR) *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (v) => setState(() => _paymentMode = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: 'Reference'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Record Settlement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
