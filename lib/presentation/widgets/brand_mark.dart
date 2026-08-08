import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../core/config/theme.dart';

/// The Green Market brand mark — a leaf badge on a brand gradient.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(radius ?? size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        MingCuteIcons.mgc_leaf_2_fill,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}
