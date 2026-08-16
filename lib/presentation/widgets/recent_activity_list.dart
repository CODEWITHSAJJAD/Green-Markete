import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/batch_model.dart';
import '../pages/batches/batch_detail_page.dart';
import 'green_card.dart';
import 'status_pill.dart';

class RecentActivityList extends StatelessWidget {
  final List<BatchModel> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(
              HeroIcons.inbox,
              size: 42,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 10),
            Text(
              'No active batches in supply chain',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: activities.map((batch) {
        final title = (batch.productName != null && batch.productName!.isNotEmpty)
            ? batch.productName!
            : 'Produce Batch';

        return GreenCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => BatchDetailPage(batchId: batch.id),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  HeroIcons.cube,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${batch.batchCode}${batch.supplierName != null && batch.supplierName!.isNotEmpty ? ' • ${batch.supplierName}' : ''} • ${batch.totalQuantity.toStringAsFixed(batch.totalQuantity.truncateToDouble() == batch.totalQuantity ? 0 : 1)} ${batch.quantityUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(status: batch.status),
                  const SizedBox(height: 5),
                  Text(
                    CurrencyFormatter.format(batch.totalPurchaseCost),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
