import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../core/config/theme.dart';

/// The official MandiRoznamcha brand logo and icon mark.
/// Resolution-independent, vector-sharp, and adaptable for dark/light surfaces.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showUrdu;
  final bool isDarkBackground;

  const BrandLogo({
    super.key,
    this.size = 56,
    this.showText = false,
    this.showUrdu = false,
    this.isDarkBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDarkBackground ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: isDarkBackground
              ? const Color(0xFF334155)
              : AppColors.divider,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkBackground ? Colors.black : AppColors.primary)
                .withValues(alpha: 0.18),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background subtle emerald glow
            Container(
              width: size * 0.58,
              height: size * 0.58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.15),
              ),
            ),
            // Produce & Mandi Emblem Icon
            Icon(
              MingCuteIcons.mgc_leaf_2_fill,
              size: size * 0.52,
              color: AppColors.emerald,
            ),
            // Golden Harvest Accent Sprout Dot
            Positioned(
              top: size * 0.22,
              right: size * 0.22,
              child: Container(
                width: size * 0.14,
                height: size * 0.14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary, // Champagne Amber
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!showText) {
      return iconContainer;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconContainer,
        SizedBox(width: size * 0.24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MandiRoznamcha',
              style: GoogleFonts.plusJakartaSans(
                color: isDarkBackground ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.42,
                letterSpacing: -0.4,
              ),
            ),
            if (showUrdu) ...[
              const SizedBox(height: 1),
              Text(
                'منڈی روزنامچہ',
                style: GoogleFonts.notoNastaliqUrdu(
                  color: isDarkBackground
                      ? AppColors.emerald
                      : AppColors.emeraldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.28,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
