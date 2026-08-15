import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../app_dropdown.dart';
import 'wizard_group_selector.dart';

class WizardExpensesStep extends StatefulWidget {
  final int groupCount;
  final int activeGroup;
  final ValueChanged<int> onGroupSelected;
  final List<Map<String, dynamic>> expensesForActiveGroup;
  final ValueChanged<List<Map<String, dynamic>>> onExpensesChanged;
  final VoidCallback onAddExpense;

  const WizardExpensesStep({
    super.key,
    required this.groupCount,
    required this.activeGroup,
    required this.onGroupSelected,
    required this.expensesForActiveGroup,
    required this.onExpensesChanged,
    required this.onAddExpense,
  });

  @override
  State<WizardExpensesStep> createState() => _WizardExpensesStepState();
}

class _WizardExpensesStepState extends State<WizardExpensesStep> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardGroupSelector(
            groupCount: widget.groupCount,
            activeGroup: widget.activeGroup,
            onGroupSelected: widget.onGroupSelected,
          ),
          const Text(
            'Add expenses (optional). These will appear in batch P&L breakdown.',
          ),
          const SizedBox(height: 16),
          _expenseList(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onAddExpense,
              icon: const Icon(MingCuteIcons.mgc_add_line),
              label: const Text('Add expense'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseList() {
    final theme = Theme.of(context);
    final expenses = widget.expensesForActiveGroup;
    return Column(
      children: List.generate(expenses.length, (i) {
        final e = expenses[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Expense ${i + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      MingCuteIcons.mgc_delete_3_line,
                      size: 20,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete expense',
                    onPressed: () {
                      final next = [...expenses];
                      next.removeAt(i);
                      widget.onExpensesChanged(next);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppDropdown<String>(
                value: e['expense_side'] as String?,
                labelText: 'Expense Side',
                items: const [
                  DropdownItem(
                    value: 'purchaser',
                    child: Text('Purchaser Side'),
                  ),
                  DropdownItem(
                    value: 'transport',
                    child: Text('Transport Side'),
                  ),
                  DropdownItem(
                    value: 'seller',
                    child: Text('Seller Side'),
                  ),
                ],
                onChanged: (v) {
                  setState(() => e['expense_side'] = v ?? 'purchaser');
                  widget.onExpensesChanged(expenses);
                },
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                value: e['expense_type'] as String?,
                labelText: 'Expense Type',
                items: const [
                  DropdownItem(
                    value: 'daily_charge',
                    child: Text('Daily Charge'),
                  ),
                  DropdownItem(
                    value: 'labor',
                    child: Text('Labor / Handling'),
                  ),
                  DropdownItem(
                    value: 'accountant',
                    child: Text('Accountant Fee'),
                  ),
                  DropdownItem(
                    value: 'source_stall_fee',
                    child: Text('Stall Fee (Source)'),
                  ),
                  DropdownItem(
                    value: 'destination_stall_fee',
                    child: Text('Stall Fee (Destination)'),
                  ),
                  DropdownItem(
                    value: 'transport',
                    child: Text('Main Transport'),
                  ),
                  DropdownItem(
                    value: 'local_transport',
                    child: Text('Local Transport / Cartage'),
                  ),
                  DropdownItem(
                    value: 'misc',
                    child: Text('Miscellaneous / Other'),
                  ),
                ],
                onChanged: (v) {
                  setState(() => e['expense_type'] = v ?? 'misc');
                  widget.onExpensesChanged(expenses);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: e['amount'].toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixIcon: Icon(MingCuteIcons.mgc_currency_dollar_line, size: 18),
                ),
                onChanged: (v) {
                  e['amount'] = double.tryParse(v) ?? 0.0;
                  widget.onExpensesChanged(expenses);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      value: e['payment_mode'] as String?,
                      labelText: 'Payment Mode',
                      items: const [
                        DropdownItem(
                          value: 'cash',
                          child: Text('Cash'),
                        ),
                        DropdownItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => e['payment_mode'] = v ?? 'cash');
                        widget.onExpensesChanged(expenses);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: e['expense_date']?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        prefixIcon: Icon(MingCuteIcons.mgc_calendar_line, size: 18),
                      ),
                      onChanged: (v) {
                        e['expense_date'] = v.isEmpty
                            ? DateTime.now().toIso8601String().split('T').first
                            : v;
                        widget.onExpensesChanged(expenses);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: e['description']?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Description / Notes (optional)',
                  prefixIcon: Icon(MingCuteIcons.mgc_edit_line, size: 18),
                ),
                onChanged: (v) {
                  e['description'] = v.isEmpty ? null : v;
                  widget.onExpensesChanged(expenses);
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
