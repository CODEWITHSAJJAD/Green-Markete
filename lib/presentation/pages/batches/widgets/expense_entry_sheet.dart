import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';

Future<Map<String, dynamic>?> showExpenseEntrySheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ExpenseEntrySheet(),
  );
}

class _ExpenseEntrySheet extends StatefulWidget {
  const _ExpenseEntrySheet();

  @override
  State<_ExpenseEntrySheet> createState() => _ExpenseEntrySheetState();
}

class _ExpenseEntrySheetState extends State<_ExpenseEntrySheet> {
  String _selectedType = 'labor';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _paidBy = 'self';
  String _paymentMode = 'cash';
  DateTime _date = DateTime.now();

  static const _expenseTypes = [
    ('labor', 'Labor'),
    ('daily_charge', 'Daily Charge'),
    ('stall_fee', 'Stall Fee'),
    ('transport', 'Transport'),
    ('local_transport', 'Local Transport'),
    ('accountant', 'Accountant'),
    ('packing', 'Packing'),
    ('misc', 'Miscellaneous'),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Expense Type', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _expenseTypes.map((type) {
                final isSelected = _selectedType == type.$1;
                return ChoiceChip(
                  label: Text(type.$2),
                  selected: isSelected,
                  onSelected: (v) => setState(() => _selectedType = type.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (PKR)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType == 'daily_charge' ? 'self' : _paidBy,
              decoration: const InputDecoration(labelText: 'Paid By'),
              items: const [
                DropdownMenuItem(value: 'self', child: Text('Self')),
                DropdownMenuItem(value: 'partner', child: Text('Partner')),
              ],
              onChanged: (v) => setState(() => _paidBy = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (v) => setState(() => _paymentMode = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormatter.toDDMMYYYY(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'expense_type': _selectedType,
                    'amount': double.tryParse(_amountController.text) ?? 0,
                    'description': _descriptionController.text,
                    'paid_by': _paidBy,
                    'payment_mode': _paymentMode,
                    'expense_date': DateFormatter.toISO(_date),
                  });
                },
                child: const Text('Save Expense'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
