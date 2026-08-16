import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/packing_record_model.dart';
import '../../providers/batch_provider.dart';
import '../empty_state.dart';
import '../green_card.dart';
import 'batch_metric_card.dart';

class BatchPackingTab extends StatelessWidget {
  final BatchModel batch;

  const BatchPackingTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final records = detailProvider.packingRecords;
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: HeroIcons.archive_box,
          title: 'No packing records added',
          subtitle: 'Tap the "+" button below to record crate, bag, or custom weight packaging breakdowns.',
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
        GreenCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: buildBatchMetric(Theme.of(context), 'Packed Units', totalUnits.toStringAsFixed(0)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBatchMetric(
                  Theme.of(context),
                  'Packing Cost',
                  CurrencyFormatter.format(totalCost),
                ),
              ),
            ],
          ),
        ),
        ...records.map(_packingTile),
      ],
    );
  }

  Widget _packingTile(PackingRecordModel record) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(HeroIcons.archive_box, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.unitCount} × ${record.unitType.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.format(record.costPerUnit)} / unit labor & packing material',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(record.totalPackingCost),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
