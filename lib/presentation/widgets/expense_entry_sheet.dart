import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/batch_model.dart';
import '../providers/auth_provider.dart';
import '../providers/batch_provider.dart';
import '../providers/partner_provider.dart';

Future<void> showExpenseEntrySheet(
  BuildContext context, {
  required String batchId,
  String defaultSide = 'purchaser',
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _ExpenseEntrySheet(batchId: batchId, defaultSide: defaultSide),
    ),
  );
}

class _ExpenseEntrySheet extends StatefulWidget {
  final String batchId;
  final String defaultSide;

  const _ExpenseEntrySheet({required this.batchId, required this.defaultSide});

  @override
  State<_ExpenseEntrySheet> createState() => _ExpenseEntrySheetState();
}

class _ExpenseEntrySheetState extends State<_ExpenseEntrySheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _side = 'purchaser';
  String _type = 'misc';
  String _paymentMode = 'cash';
  String? _paidBy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _side = widget.defaultSide;
    if (_side == 'transport') _type = 'transport';
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<PartnerProvider>().load(businessId);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<ExpenseProvider>().add(
          widget.batchId,
          ExpenseCreate(
            expenseSide: _side,
            expenseType: _type,
            amount: amount,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            paidBy: _paidBy,
            paymentMode: _paymentMode,
            paymentReference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
            expenseDate: DateTime.now().toIso8601String().split('T').first,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partners = context.watch<PartnerProvider>().partners;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Expense', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _side,
                    decoration: const InputDecoration(labelText: 'Side'),
                    items: const [
                      DropdownMenuItem(value: 'purchaser', child: Text('Purchaser')),
                      DropdownMenuItem(value: 'transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'seller', child: Text('Seller')),
                    ],
                    onChanged: (v) => setState(() => _side = v ?? 'purchaser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'daily_charge', child: Text('Daily Charge')),
                      DropdownMenuItem(value: 'labor', child: Text('Labor')),
                      DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                      DropdownMenuItem(value: 'packing', child: Text('Packing')),
                      DropdownMenuItem(value: 'stall_fee', child: Text('Stall Fee')),
                      DropdownMenuItem(value: 'transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'local_transport', child: Text('Local Transport')),
                      DropdownMenuItem(value: 'misc', child: Text('Misc')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'misc'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _paidBy,
              decoration: const InputDecoration(labelText: 'Paid by (partner)'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('—')),
                ...partners.map((p) => DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(p.fullName),
                    )),
              ],
              onChanged: (v) => setState(() => _paidBy = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment mode'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (v) => setState(() => _paymentMode = v ?? 'cash'),
            ),
            if (_paymentMode == 'bank_transfer') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Bank reference'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
