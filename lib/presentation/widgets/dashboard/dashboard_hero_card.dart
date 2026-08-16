import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../pages/reports/reports_page.dart';
import '../../providers/dashboard_provider.dart';

/// Executive Financial Overview Card designed with real-world fintech aesthetics.
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
        color: AppColors.primary, // Executive Obsidian Slate #0F172A
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const ReportsPage()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Clean label + Net Margin pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL TURNOVER',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isProfit
                            ? AppColors.emerald.withValues(alpha: 0.15)
                            : AppColors.rose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isProfit
                              ? AppColors.emerald.withValues(alpha: 0.45)
                              : AppColors.rose.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? HeroIcons.arrow_trending_up
                                : HeroIcons.arrow_trending_down,
                            size: 12,
                            color: isProfit ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfit
                                ? '${marginPct > 0 ? '+${marginPct.toStringAsFixed(1)}%' : '0%'} Margin'
                                : '${marginPct.toStringAsFixed(1)}% Loss',
                            style: GoogleFonts.inter(
                              color: isProfit ? const Color(0xFF34D399) : const Color(0xFFF87171),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Big Number
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(provider.totalRevenue),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hairline Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                const SizedBox(height: 14),

                // 2-Column Balanced Financial Split
                Row(
                  children: [
                    // Column 1: Today's Sales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY\'S SALES',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            CurrencyFormatter.format(provider.todaySales),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    const SizedBox(width: 16),
                    // Column 2: Net Profit / Gain
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProfit ? 'EST. NET PROFIT' : 'NET DEFICIT',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            CurrencyFormatter.format(provider.totalProfitLoss.abs()),
                            style: GoogleFonts.inter(
                              color: isProfit ? const Color(0xFF34D399) : const Color(0xFFF87171),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
