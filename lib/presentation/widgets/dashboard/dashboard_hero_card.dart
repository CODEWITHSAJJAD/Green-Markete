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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const ReportsPage()),
        ),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F3D1F), // Deep emerald green
                Color(0xFF1B5E20), // Primary green
                Color(0xFF0B2E16), // Dark forest green
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3D1F).withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Title + Profit/Loss Badge + Arrow
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      MingCuteIcons.mgc_chart_line_line,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Lifetime Revenue',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(provider.totalRevenue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    MingCuteIcons.mgc_right_line,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Lifetime Profit/Loss Highlight Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isProfit
                      ? const Color(0xFF16A34A).withValues(alpha: 0.22)
                      : const Color(0xFFDC2626).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isProfit
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.35)
                        : const Color(0xFFF87171).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProfit
                          ? MingCuteIcons.mgc_trending_up_line
                          : MingCuteIcons.mgc_trending_down_line,
                      size: 18,
                      color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isProfit ? 'Lifetime Profit:' : 'Lifetime Loss:',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isProfit
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(provider.totalProfitLoss.abs()),
                                style: TextStyle(
                                  color: isProfit
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF87171),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (marginPct != 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isProfit
                                    ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                                    : const Color(0xFFF87171).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${isProfit ? '+' : ''}${marginPct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Stats Row: Today's Revenue & Sales & Active Batches
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Revenue',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(provider.todaySales),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Activity',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${provider.todaySalesCount} sales · ${provider.activeBatchesCount} active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
