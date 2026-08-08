import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

/// A soft, elevated surface card used across the app.
class GreenCard extends StatelessWidget {
  const GreenCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.surface;
    final decoration = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: (borderColor ?? AppColors.divider).withValues(alpha: 0.7)),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    final card = Container(
      margin: margin,
      decoration: decoration,
      child: content,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Ink(
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}
