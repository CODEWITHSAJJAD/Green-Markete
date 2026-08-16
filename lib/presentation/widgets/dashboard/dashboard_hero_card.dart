import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/theme.dart';
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
        color: AppColors.primary, // Solid Luxury Obsidian Midnight Slate
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
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
          borderRadius: BorderRadius.circular(22),
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
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        HeroIcons.wallet,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total Gross Turnover',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit
                            ? AppColors.emerald.withValues(alpha: 0.18)
                            : AppColors.rose.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isProfit
                              ? AppColors.emerald.withValues(alpha: 0.5)
                              : AppColors.rose.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? HeroIcons.arrow_trending_up
                                : HeroIcons.arrow_trending_down,
                            size: 13,
                            color: isProfit ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfit ? 'Net Profit' : 'Net Loss',
                            style: GoogleFonts.plusJakartaSans(
                              color: isProfit ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Metric: Total Revenue Amount with Plus Jakarta Sans
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(provider.totalRevenue),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Net Profit Row with Margin Percentage
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isProfit ? 'Estimated Net Earnings:' : 'Estimated Loss:',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
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
                                  style: GoogleFonts.inter(
                                    color: isProfit
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFFFCA5A5),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (marginPct != 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${isProfit ? '+' : ''}${marginPct.toStringAsFixed(1)}%)',
                                    style: GoogleFonts.inter(
                                      color: isProfit
                                          ? AppColors.emerald
                                          : AppColors.rose,
                                      fontSize: 11.5,
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
                      HeroIcons.clock,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Today: ${CurrencyFormatter.format(provider.todaySales)} · ${provider.todaySalesCount} sales · ${provider.activeBatchesCount} batches in market',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      HeroIcons.chevron_right,
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
