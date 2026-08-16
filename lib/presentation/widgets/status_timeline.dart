import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<String> statuses;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
    this.statuses = const [
      'purchased',
      'packed',
      'in_transit',
      'delivered',
      'selling',
      'closed',
    ],
  });

  int get _currentIndex => statuses.indexOf(currentStatus);

  String _label(String s) {
    switch (s) {
      case 'in_transit':
        return 'In Transit';
      case 'selling':
        return 'Selling';
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curIdx = _currentIndex >= 0 ? _currentIndex : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(statuses.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connecting line
              final stepIdx = i ~/ 2;
              final isPassed = stepIdx < curIdx;
              return Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: isPassed
                    ? AppColors.emerald
                    : AppColors.divider,
              );
            }

            final stepIdx = i ~/ 2;
            final status = statuses[stepIdx];
            final isCurrent = stepIdx == curIdx;
            final isPassed = stepIdx < curIdx;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : isPassed
                            ? AppColors.emerald
                            : AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : isPassed
                              ? AppColors.emerald
                              : AppColors.divider,
                      width: 1.5,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isPassed
                      ? const Icon(HeroIcons.check, color: Colors.white, size: 16)
                      : isCurrent
                          ? const Icon(HeroIcons.bolt, color: Colors.white, size: 16)
                          : Text(
                              '${stepIdx + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                ),
                const SizedBox(height: 6),
                Text(
                  _label(status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrent
                        ? AppColors.primary
                        : isPassed
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}