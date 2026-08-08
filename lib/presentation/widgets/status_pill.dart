import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

/// A compact status indicator with a colored dot and label.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.showDot = true});

  final String status;
  final bool showDot;

  Color get _color {
    switch (status.toLowerCase()) {
      case 'purchased':
        return AppColors.textSecondary;
      case 'packed':
        return const Color(0xFF2563EB);
      case 'in_transit':
        return AppColors.pending;
      case 'delivered':
        return AppColors.success;
      case 'selling':
        return AppColors.primary;
      case 'closed':
        return AppColors.textTertiary;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'in_transit':
        return 'In Transit';
      case 'purchased':
        return 'Purchased';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
