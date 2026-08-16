import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/batch_vehicle_model.dart';
import '../../../data/models/packing_record_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../confirm_dialog.dart';
import '../empty_state.dart';
import '../green_card.dart';
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
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: HeroIcons.truck,
          title: 'No transport loads logged',
          subtitle: 'Tap the "+" button below to assign freight vehicles and track logistics costs.',
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
          (p) => p['role'] == transportPaidBy || p['role'] == 'both',
        )
        .map((p) => p['partner_id'] as String?)
        .whereType<String>()
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        GreenCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: buildBatchMetric(theme, 'Active Vehicles', '${grouped.length} Vehicles'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Total Freight Cost',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        if (transportPartnerId != null && context.read<AuthProvider>().canEditPurchaserSide) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => showPayTransportDialog(
                context,
                batch: batch,
                totalCost: totalCost,
                transportPartnerId: transportPartnerId,
              ),
              icon: const Icon(HeroIcons.banknotes, size: 18),
              label: Text(
                'Pay Transport Direct Expense',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
    final first = loads.first;
    final combinedUnits = loads.fold<double>(0, (acc, l) => acc + l.unitCount);
    final fare = loads.fold<double>(0, (acc, l) => acc + l.totalCost);

    return GreenCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.skySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sky.withValues(alpha: 0.2), width: 1),
                ),
                child: const Icon(HeroIcons.truck, color: AppColors.sky, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      first.vehiclePlateNumber ?? 'Vehicle',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (first.driverName != null && first.driverName!.isNotEmpty)
                      Text(
                        'Driver: ${first.driverName!}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(fare),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Total Fare',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),
          ...loads.map(
            (l) => _loadRow(
              context,
              batch,
              l,
              _transportLoadLabel(l, packingById),
            ),
          ),
          if (combinedUnits > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Combined Vehicle Load',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${combinedUnits.toStringAsFixed(0)} units',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
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
    final canDelete = context.read<AuthProvider>().canEditPurchaserSide;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            CurrencyFormatter.format(load.totalCost),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );

    if (!canDelete) return row;

    return Dismissible(
      key: ValueKey('load-${load.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.roseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(HeroIcons.trash, color: AppColors.rose, size: 18),
      ),
      confirmDismiss: (_) async {
        final ok = await showConfirmDialog(
          context,
          title: 'Delete transport load?',
          message: 'Are you sure you want to remove this vehicle load record?',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (ok != true) return false;
        await context.read<BatchDetailProvider>().deleteVehicleLoad(load.id);
        if (context.mounted) {
          context.read<BatchPLProvider>().load(batch.id);
        }
        return true;
      },
      child: row,
    );
  }

  String _transportLoadLabel(
    BatchVehicleModel load,
    Map<String, PackingRecordModel> packingById,
  ) {
    if (load.packingRecordId != null && packingById.containsKey(load.packingRecordId)) {
      final p = packingById[load.packingRecordId]!;
      return '${load.unitCount.toStringAsFixed(0)} × ${p.unitType.toUpperCase()}';
    }
    return '${load.unitCount.toStringAsFixed(0)} units (Freight: ${CurrencyFormatter.format(load.totalCost)})';
  }
}
