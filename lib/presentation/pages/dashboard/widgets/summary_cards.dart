import 'package:flutter/material.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/report_model.dart';

class SummaryCards extends StatelessWidget {
  final DashboardSummaryModel summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SummaryCard(
            title: "Today's Sales",
            value: CurrencyFormatter.format(summary.todaySales),
            icon: Icons.today,
            color: AppColors.primary,
          ),
          _SummaryCard(
            title: 'Active Batches',
            value: summary.activeBatches.toString(),
            icon: Icons.inventory_2,
            color: AppColors.primaryLight,
          ),
          _SummaryCard(
            title: 'Outstanding Credit',
            value: CurrencyFormatter.format(summary.outstandingCredit),
            icon: Icons.credit_score,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
