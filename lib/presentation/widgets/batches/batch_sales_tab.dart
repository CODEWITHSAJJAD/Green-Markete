import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../empty_state.dart';
import '../green_card.dart';
import 'batch_dialogs.dart';
import 'batch_metric_card.dart';

class BatchSalesTab extends StatelessWidget {
  final BatchModel batch;

  const BatchSalesTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    if (saleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (saleProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
              const SizedBox(height: 10),
              Text(saleProvider.error!),
            ],
          ),
        ),
      );
    }
    final sales = saleProvider.sales;
    if (sales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: HeroIcons.shopping_bag,
          title: 'No sales recorded yet',
          subtitle: 'Tap the "+" button below to record wholesale sales against this batch.',
        ),
      );
    }
    final totalQty = sales.fold<double>(0, (acc, s) => acc + s.quantitySold);
    final totalRev = sales.fold<double>(0, (acc, s) => acc + s.totalAmount);
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
                  'Units Sold',
                  '${totalQty.toStringAsFixed(0)} ${batch.quantityUnit}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBatchMetric(
                  Theme.of(context),
                  'Gross Revenue',
                  CurrencyFormatter.format(totalRev),
                ),
              ),
            ],
          ),
        ),
        ...sales.map((s) => _saleTile(context, s, batch.quantityUnit)),
      ],
    );
  }

  Widget _saleTile(BuildContext context, SaleModel sale, String unit) {
    final walkInCredit = sale.customerId == null && sale.creditAmount > 0;
    final canCollect = walkInCredit && context.read<AuthProvider>().canEditSellerSide;
    final modeColor = getPaymentModeColor(Theme.of(context), sale.paymentMode);

    return GreenCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              getPaymentModeIcon(sale.paymentMode),
              color: modeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sale.quantitySold.toStringAsFixed(0)} $unit × ${CurrencyFormatter.format(sale.pricePerUnit)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    sale.saleDate,
                    sale.paymentMode.toUpperCase(),
                    if (walkInCredit) 'Due: ${CurrencyFormatter.format(sale.creditAmount)}',
                  ].join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: walkInCredit ? AppColors.rose : AppColors.textSecondary,
                    fontWeight: walkInCredit ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(sale.totalAmount),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                ),
              ),
              if (canCollect) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => showCollectWalkInCreditDialog(context, sale),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Text(
                      'Collect Cash',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
