import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

/// A modern, luxury status indicator with a colored dot and clear label.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.showDot = true});

  final String status;
  final bool showDot;

  Color get _color {
    switch (status.toLowerCase().trim()) {
      case 'purchased':
        return AppColors.textSecondary;
      case 'packed':
        return AppColors.indigo;
      case 'in_transit':
        return AppColors.sky;
      case 'delivered':
        return AppColors.emerald;
      case 'selling':
        return AppColors.secondary;
      case 'closed':
        return AppColors.textTertiary;
      case 'paid':
      case 'cleared':
        return AppColors.emerald;
      case 'partial':
      case 'pending':
        return AppColors.amber;
      case 'unpaid':
      case 'overdue':
        return AppColors.rose;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    final clean = status.toLowerCase().trim();
    switch (clean) {
      case 'in_transit':
        return 'In Transit';
      case 'purchased':
        return 'Purchased';
      case 'packed':
        return 'Packed';
      case 'delivered':
        return 'Delivered';
      case 'selling':
        return 'Selling in Market';
      case 'closed':
        return 'Closed';
      default:
        if (clean.isEmpty) return '';
        final words = clean.replaceAll('_', ' ').split(' ');
        return words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
