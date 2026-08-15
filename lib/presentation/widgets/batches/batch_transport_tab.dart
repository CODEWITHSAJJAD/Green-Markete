import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/batch_vehicle_model.dart';
import '../../../data/models/packing_record_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../confirm_dialog.dart';
import 'batch_dialogs.dart';
import 'batch_metric_card.dart';

class BatchTransportTab extends StatelessWidget {
  final BatchModel batch;

  const BatchTransportTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loads = detailProvider.vehicleLoads;
    if (loads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No vehicle loads yet. Tap + to assign transport to a vehicle.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final grouped = <String, List<BatchVehicleModel>>{};
    for (final l in loads) {
      grouped.putIfAbsent(l.vehicleId, () => []).add(l);
    }
    final packingById = {
      for (final p in detailProvider.packingRecords) p.id: p,
    };
    final totalCost = loads.fold<double>(0, (acc, l) => acc + l.totalCost);
    final transportPaidBy = batch.transportPaidBy ?? 'purchaser';
    final transportPartnerId = detailProvider.batchPartners
        .where(
          (p) =>
              p['role'] == transportPaidBy ||
              p['role'] == 'both',
        )
        .map((p) => p['partner_id'] as String?)
        .whereType<String>()
        .firstOrNull;

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
                child: buildBatchMetric(theme, 'Vehicles', '${grouped.length}'),
              ),
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Transport Cost',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        if (transportPartnerId != null &&
            context.read<AuthProvider>().canEditPurchaserSide) ...[
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () => showPayTransportDialog(
              context,
              batch: batch,
              totalCost: totalCost,
              transportPartnerId: transportPartnerId,
            ),
            icon: const Icon(MingCuteIcons.mgc_wallet_3_line),
            label: const Text('Pay Transport'),
          ),
          const SizedBox(height: 8),
        ],
        ...grouped.entries.map(
          (entry) => _vehicleGroup(context, batch, entry.value, packingById),
        ),
      ],
    );
  }

  Widget _vehicleGroup(
    BuildContext context,
    BatchModel batch,
    List<BatchVehicleModel> loads,
    Map<String, PackingRecordModel> packingById,
  ) {
    final theme = Theme.of(context);
    final first = loads.first;
    final combinedUnits = loads.fold<double>(0, (acc, l) => acc + l.unitCount);
    final fare = loads.fold<double>(0, (acc, l) => acc + l.totalCost);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  MingCuteIcons.mgc_truck_line,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.vehiclePlateNumber ?? 'Vehicle',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (first.driverName != null && first.driverName!.isNotEmpty)
                      Text(first.driverName!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(fare),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                  Text('Fare', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          ...loads.map(
            (l) => _loadRow(
              context,
              batch,
              l,
              _transportLoadLabel(l, packingById),
            ),
          ),
          if (combinedUnits > 0) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loads.length > 1
                        ? '${loads.length} loads on this vehicle'
                        : 'Units loaded',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${combinedUnits.toStringAsFixed(combinedUnits % 1 == 0 ? 0 : 1)} units total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _loadRow(
    BuildContext context,
    BatchModel batch,
    BatchVehicleModel load,
    String label,
  ) {
    final theme = Theme.of(context);
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (load.costType == 'per_packing' && load.unitCount > 0)
                      '${load.unitCount.toStringAsFixed(load.unitCount % 1 == 0 ? 0 : 1)} units × ${CurrencyFormatter.format(load.transportCost)}/unit'
                    else if (load.costType == 'per_packing')
                      '${CurrencyFormatter.format(load.transportCost)}/unit'
                    else if (load.costType == 'lump_sum')
                      'Lump sum'
                    else
                      'Flat fare',
                    load.loadDate,
                  ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(load.totalCost),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
    final canDelete = context.read<AuthProvider>().canEditPurchaserSide;
    if (!canDelete) return tile;
    return Dismissible(
      key: ValueKey('vehicle-load-${load.id}'),
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
        final batchPLProvider = context.read<BatchPLProvider>();
        final ok = await showConfirmDialog(
          context,
          title: 'Remove this load?',
          message:
              'The transport load for ${load.vehiclePlateNumber ?? 'this vehicle'} will be removed from this batch.',
          confirmLabel: 'Remove',
          isDestructive: true,
        );
        if (ok != true) return false;
        try {
          await batchDetailProvider.deleteVehicleLoad(load.id);
          if (!context.mounted) return false;
          batchPLProvider.load(batch.id);
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

  String _transportLoadLabel(
    BatchVehicleModel load,
    Map<String, PackingRecordModel> packingById,
  ) {
    final id = load.packingRecordId;
    final packing = id == null ? null : packingById[id];
    if (packing != null) {
      final type = packing.unitType.toLowerCase();
      if (type.isEmpty || type.contains('custom') || type.contains('loose')) {
        final name =
            packing.unitLabel == null || packing.unitLabel!.isEmpty
                ? 'Loose'
                : packing.unitLabel!;
        return name;
      }
      return '${packing.unitType} × ${packing.unitCount}';
    }
    return load.packingLabel ?? 'Load';
  }
}
