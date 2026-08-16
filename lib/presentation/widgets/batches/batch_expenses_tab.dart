import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../empty_state.dart';
import '../green_card.dart';

class BatchExpensesTab extends StatelessWidget {
  final BatchModel batch;

  const BatchExpensesTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    if (expenseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (expenseProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
              const SizedBox(height: 10),
              Text(expenseProvider.error!),
            ],
          ),
        ),
      );
    }
    final expenses = expenseProvider.expenses;
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: HeroIcons.receipt_percent,
          title: 'No expenses recorded yet',
          subtitle: 'Tap the "+" button below to record labor, market fees, transport, or packing expenses.',
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
          final isPurchaser = entry.key == 'purchaser';
          final sideLabel = isPurchaser ? 'Purchaser / Procurement Outlay' : 'Seller / Market Realization';
          final sideTotal = entry.value.fold<double>(
            0,
            (acc, e) => acc + (e as ExpenseModel).amount,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10, top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isPurchaser ? AppColors.primarySurface : AppColors.amberSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPurchaser ? AppColors.divider : AppColors.amber.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sideLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isPurchaser ? AppColors.primary : AppColors.amber,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(sideTotal),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: isPurchaser ? AppColors.primary : AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((e) => _expenseTile(context, e as ExpenseModel)),
              const SizedBox(height: 12),
            ],
          );
        }),
        if (voidedExpenses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              'VOIDED EXPENSES (Audited & Excluded from P&L)',
              style: GoogleFonts.inter(
                color: AppColors.rose,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...voidedExpenses.map((e) => _expenseTile(context, e)),
        ],
      ],
    );
  }

  Widget _expenseTile(BuildContext context, ExpenseModel expense) {
    final isVoided = expense.isVoided;
    final tile = GreenCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isVoided ? AppColors.surfaceAlt : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVoided ? HeroIcons.no_symbol : HeroIcons.receipt_percent,
              color: isVoided ? AppColors.rose : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.expenseType.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isVoided ? AppColors.textTertiary : AppColors.textPrimary,
                    decoration: isVoided ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (expense.description != null && expense.description!.isNotEmpty) expense.description,
                    if (expense.expenseDate != null) expense.expenseDate,
                    if (expense.paymentMode != null) expense.paymentMode!.toUpperCase(),
                    if (isVoided && expense.voidedReason != null && expense.voidedReason!.isNotEmpty)
                      'Voided: ${expense.voidedReason}',
                  ].whereType<String>().join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isVoided ? AppColors.rose : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(expense.amount),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isVoided ? AppColors.textTertiary : AppColors.textPrimary,
              decoration: isVoided ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );

    if (isVoided) return tile;

    final canVoid = (context.read<AuthProvider>().user?.role ?? '').canVoidExpense;
    if (!canVoid) return tile;

    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.roseSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.rose, width: 1),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          HeroIcons.trash,
          color: AppColors.rose,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Void Expense?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Voided expenses are archived for audit logs and removed from P&L totals.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason for voiding (required)',
                    hintText: 'e.g. Duplicate entry, incorrect amount',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
                onPressed: () {
                  if (reasonCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Void Expense'),
              ),
            ],
          ),
        );
        if (ok != true) return false;
        final voided = await expenseProvider.voidExpense(
          expense.id,
          reasonCtrl.text.trim(),
        );
        if (voided) {
          batchPLProvider.load(batch.id);
          batchDetailProvider.load(batch.id);
        }
        return voided;
      },
      child: tile,
    );
  }
}
