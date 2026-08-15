import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/packing_return_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../confirm_dialog.dart';
import 'batch_metric_card.dart';

class BatchReturnsTab extends StatelessWidget {
  final BatchModel batch;

  const BatchReturnsTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final returns = detailProvider.returns;
    if (returns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No returns yet. Tap + to record goods returned by a buyer.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final totalQty = returns.fold<double>(0, (acc, r) => acc + r.quantity);
    final totalCost = returns.fold<double>(
      0,
      (acc, r) => acc + r.totalReturnCost,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Returned',
                  '${totalQty.toStringAsFixed(0)} ${batch.unit}',
                ),
              ),
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Return Value',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        ...returns.map((r) => _returnTile(context, r)),
      ],
    );
  }

  Widget _returnTile(BuildContext context, PackingReturnModel item) {
    final theme = Theme.of(context);
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.12),
        child: Icon(
          MingCuteIcons.mgc_arrow_to_left_line,
          color: theme.colorScheme.error,
          size: 18,
        ),
      ),
      title: Text(
        '${item.quantity.toStringAsFixed(0)} ${item.unitType ?? 'units'} returned',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        [
          item.packingLabel,
          item.returnDate,
          item.notes,
        ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
      ),
      trailing: item.totalReturnCost > 0
          ? Text(
              CurrencyFormatter.format(item.totalReturnCost),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Roboto Mono',
              ),
            )
          : null,
    );
    final canDelete = context.read<AuthProvider>().canEditPurchaserSide;
    if (!canDelete) return tile;
    return Dismissible(
      key: ValueKey('return-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          MingCuteIcons.mgc_delete_2_line,
          color: theme.colorScheme.error,
        ),
      ),
      confirmDismiss: (_) async {
        final batchDetailProvider = context.read<BatchDetailProvider>();
        final ok = await showConfirmDialog(
          context,
          title: 'Remove this return?',
          message:
              'The return of ${item.quantity.toStringAsFixed(0)} units will be removed from this batch.',
          confirmLabel: 'Remove',
          isDestructive: true,
        );
        if (ok != true) return false;
        try {
          await batchDetailProvider.deleteReturn(item.id);
          if (!context.mounted) return false;
          context.read<BatchPLProvider>().load(batch.id);
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
