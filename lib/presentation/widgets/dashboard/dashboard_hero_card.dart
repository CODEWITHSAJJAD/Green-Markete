import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../pages/reports/reports_page.dart';
import '../../providers/dashboard_provider.dart';

class DashboardHeroCard extends StatelessWidget {
  final DashboardProvider provider;

  const DashboardHeroCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isProfit = provider.totalProfitLoss >= 0;
    final totalRev = provider.totalRevenue;
    final marginPct = totalRev > 0
        ? (provider.totalProfitLoss / totalRev) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF134E2A), // Deep natural emerald
            Color(0xFF1E6B3B), // Forest green
            Color(0xFF0D381E), // Dark moss tone
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF134E2A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const ReportsPage()),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row: Label + P&L badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        MingCuteIcons.mgc_wallet_4_line,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total Gross Turnover',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit
                            ? const Color(0xFF22C55E).withValues(alpha: 0.22)
                            : const Color(0xFFEF4444).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isProfit
                              ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                              : const Color(0xFFF87171).withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? MingCuteIcons.mgc_trending_up_line
                                : MingCuteIcons.mgc_trending_down_line,
                            size: 13,
                            color: isProfit ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfit ? 'Net Profit' : 'Net Loss',
                            style: TextStyle(
                              color: isProfit ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Metric: Total Revenue Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(provider.totalRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Profit Card with Margin Percentage
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isProfit ? 'Estimated Net Earnings:' : 'Estimated Loss:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(provider.totalProfitLoss.abs()),
                                  style: TextStyle(
                                    color: isProfit
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFFCA5A5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (marginPct != 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${isProfit ? '+' : ''}${marginPct.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      color: isProfit
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFFF87171),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Today's Pulse Bar
                Row(
                  children: [
                    Icon(
                      MingCuteIcons.mgc_time_line,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Today: ${CurrencyFormatter.format(provider.todaySales)} · ${provider.todaySalesCount} sales · ${provider.activeBatchesCount} batches in market',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      MingCuteIcons.mgc_right_line,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
