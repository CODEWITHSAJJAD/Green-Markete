import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/packing_record_model.dart';
import '../../providers/batch_provider.dart';
import 'batch_metric_card.dart';

class BatchPackingTab extends StatelessWidget {
  final BatchModel batch;

  const BatchPackingTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final records = detailProvider.packingRecords;
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No packing records yet. Tap + to add one.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final totalUnits = records.fold<int>(0, (acc, r) => acc + r.unitCount);
    final totalCost = records.fold<double>(
      0,
      (acc, r) => acc + r.totalPackingCost,
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
                child: buildBatchMetric(theme, 'Units', totalUnits.toStringAsFixed(0)),
              ),
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Packing Cost',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        ...records.map((r) => _packingTile(context, r)),
      ],
    );
  }

  Widget _packingTile(BuildContext context, PackingRecordModel record) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(
          MingCuteIcons.mgc_box_3_line,
          color: theme.colorScheme.primary,
          size: 18,
        ),
      ),
      title: Text(
        record.unitLabel != null && record.unitLabel!.isNotEmpty
            ? record.unitLabel!
            : record.unitType,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${record.unitCount} × ${record.unitType} — ${CurrencyFormatter.format(record.costPerUnit)}/unit',
      ),
      trailing: Text(
        CurrencyFormatter.format(record.totalPackingCost),
        style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'Roboto Mono'),
      ),
    );
  }
}
