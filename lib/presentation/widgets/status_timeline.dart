import 'package:flutter/material.dart';

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
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isCurrent = status == currentStatus;
          final isPassed = index <= _currentIndex;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : isPassed
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isPassed
                    ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 14)
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCurrent ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                _label(status),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}