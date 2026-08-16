import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/packing_return_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../confirm_dialog.dart';
import '../empty_state.dart';
import '../green_card.dart';
import 'batch_metric_card.dart';

class BatchReturnsTab extends StatelessWidget {
  final BatchModel batch;

  const BatchReturnsTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final detailProvider = context.watch<BatchDetailProvider>();
    if (detailProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final returns = detailProvider.returns;
    if (returns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: HeroIcons.arrow_path,
          title: 'No produce returns recorded',
          subtitle: 'Tap the "+" button below to log buyer rejections or damaged packaging returns.',
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
        GreenCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: buildBatchMetric(
                  Theme.of(context),
                  'Returned Quantity',
                  '${totalQty.toStringAsFixed(0)} ${batch.quantityUnit}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBatchMetric(
                  Theme.of(context),
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

  Widget _returnTile(BuildContext context, PackingReturnModel ret) {
    final canDelete = context.read<AuthProvider>().canEditPurchaserSide;
    final tile = GreenCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.roseSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.rose.withValues(alpha: 0.2), width: 1),
            ),
            child: const Icon(HeroIcons.arrow_uturn_left, size: 20, color: AppColors.rose),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ret.quantity.toStringAsFixed(0)} ${batch.quantityUnit} Returned',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (ret.notes != null && ret.notes!.isNotEmpty) ret.notes,
                    if (ret.returnDate != null) ret.returnDate,
                  ].where((e) => e != null).join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(ret.totalReturnCost),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: AppColors.rose,
            ),
          ),
        ],
      ),
    );

    if (!canDelete) return tile;

    return Dismissible(
      key: ValueKey('return-${ret.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.roseSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.rose, width: 1),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(HeroIcons.trash, color: AppColors.rose),
      ),
      confirmDismiss: (_) async {
        final ok = await showConfirmDialog(
          context,
          title: 'Delete return record?',
          message: 'This return will be permanently removed and restored into batch inventory.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (ok != true) return false;
        await context.read<BatchDetailProvider>().deleteReturn(ret.id);
        if (context.mounted) {
          context.read<BatchPLProvider>().load(batch.id);
        }
        return true;
      },
      child: tile,
    );
  }
}
