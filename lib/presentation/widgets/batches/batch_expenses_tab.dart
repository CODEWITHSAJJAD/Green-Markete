import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';

class BatchExpensesTab extends StatelessWidget {
  final BatchModel batch;

  const BatchExpensesTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = context.watch<ExpenseProvider>();
    if (expenseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (expenseProvider.error != null) {
      return Center(child: Text(expenseProvider.error!));
    }
    final expenses = expenseProvider.expenses;
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No expenses yet. Tap + to add one.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    final activeExpenses = expenses.where((e) => !e.isVoided).toList();
    final voidedExpenses = expenses.where((e) => e.isVoided).toList();
    final grouped = <String, List<dynamic>>{};
    for (final e in activeExpenses) {
      grouped.putIfAbsent(e.expenseSide, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        ...grouped.entries.map((entry) {
          final sideLabel = entry.key.toUpperCase();
          final sideTotal = entry.value.fold<double>(
            0,
            (acc, e) => acc + (e as ExpenseModel).amount,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(sideLabel, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(sideTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((e) => _expenseTile(context, e as ExpenseModel)),
            ],
          );
        }),
        if (voidedExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'VOIDED (excluded from totals)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          ...voidedExpenses.map((e) => _expenseTile(context, e)),
        ],
      ],
    );
  }

  Widget _expenseTile(BuildContext context, ExpenseModel expense) {
    final theme = Theme.of(context);
    final isVoided = expense.isVoided;
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: isVoided
          ? Icon(
              MingCuteIcons.mgc_forbid_circle_line,
              color: theme.colorScheme.error,
              size: 22,
            )
          : null,
      title: Text(
        expense.expenseType,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isVoided
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
          decoration: isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          expense.description,
          expense.expenseDate,
          expense.paymentMode,
          if (isVoided &&
              expense.voidedReason != null &&
              expense.voidedReason!.isNotEmpty)
            'Voided: ${expense.voidedReason}',
        ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
        style: TextStyle(
          color: isVoided
              ? theme.colorScheme.error.withValues(alpha: 0.7)
              : null,
        ),
      ),
      trailing: Text(
        CurrencyFormatter.format(expense.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'Roboto Mono',
          color: isVoided
              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
          decoration: isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
    );

    if (isVoided) return tile;

    final canVoid =
        (context.read<AuthProvider>().user?.role ?? '').canVoidExpense;
    if (!canVoid) return tile;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          MingCuteIcons.mgc_forbid_circle_line,
          color: theme.colorScheme.error,
        ),
      ),
      confirmDismiss: (_) async {
        final reasonCtrl = TextEditingController();
        final expenseProvider = context.read<ExpenseProvider>();
        final batchPLProvider = context.read<BatchPLProvider>();
        final batchDetailProvider = context.read<BatchDetailProvider>();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Void expense?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Voided expenses are kept for audit and excluded from totals. This cannot be undone.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () =>
                    Navigator.pop(ctx, reasonCtrl.text.trim().isNotEmpty),
                child: const Text('Void'),
              ),
            ],
          ),
        );
        if (ok != true) return false;
        // Re-prompt if empty reason
        if (reasonCtrl.text.trim().isEmpty) {
          if (!context.mounted) return false;
          final reason2 = TextEditingController();
          final ok2 = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Reason required'),
              content: TextField(
                controller: reason2,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit'),
                ),
              ],
            ),
          );
          if (ok2 != true || reason2.text.trim().isEmpty) return false;
          reasonCtrl.text = reason2.text;
        }
        try {
          await expenseProvider.voidExpense(expense.id, reasonCtrl.text.trim());
          expenseProvider.load(batch.id);
          batchPLProvider.load(batch.id);
          batchDetailProvider.load(batch.id);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
              ),
            );
          }
          return false;
        }
      },
      child: tile,
    );
  }
}
