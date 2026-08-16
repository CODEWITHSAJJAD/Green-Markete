import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/theme.dart';

/// The official MandiRoznamcha brand logo and icon mark.
///
/// The mark reads as a leaf split by a ledger spine, with faint tally-mark
/// veins and an amber "harvest" dot — tying "mandi" (produce market) and
/// "roznamcha" (daily ledger) into one shape instead of a generic leaf icon.
/// Fully vector (CustomPainter), so it stays crisp at any size and carries
/// no icon-font dependency.
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
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: CustomPaint(
          painter: _MandiMarkPainter(
            leafLight: AppColors.emerald,
            leafDark: AppColors.emeraldDark,
            spineColor: isDarkBackground ? const Color(0xFF0F172A) : Colors.white,
            harvestDot: AppColors.secondary,
          ),
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

/// Paints the leaf-and-ledger mark: two leaf lobes (light/dark emerald)
/// split by a straight spine, faint tally-mark veins fanning off it, and
/// an amber dot in the upper-right lobe standing in for a harvest/ripe cue.
class _MandiMarkPainter extends CustomPainter {
  final Color leafLight;
  final Color leafDark;
  final Color spineColor;
  final Color harvestDot;

  _MandiMarkPainter({
    required this.leafLight,
    required this.leafDark,
    required this.spineColor,
    required this.harvestDot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = (w < h ? w : h) / 2;

    // Right lobe (lighter emerald) — a leaf half from top to bottom.
    final rightLobe = Path()
      ..moveTo(cx, cy - r)
      ..cubicTo(
        cx + r * 0.58, cy - r,
        cx + r, cy - r * 0.58,
        cx + r, cy,
      )
      ..cubicTo(
        cx + r, cy + r * 0.58,
        cx + r * 0.58, cy + r,
        cx, cy + r,
      )
      ..close();

    // Left lobe (deeper emerald).
    final leftLobe = Path()
      ..moveTo(cx, cy - r)
      ..cubicTo(
        cx - r * 0.58, cy - r,
        cx - r, cy - r * 0.58,
        cx - r, cy,
      )
      ..cubicTo(
        cx - r, cy + r * 0.58,
        cx - r * 0.58, cy + r,
        cx, cy + r,
      )
      ..close();

    canvas.drawPath(rightLobe, Paint()..color = leafLight);
    canvas.drawPath(leftLobe, Paint()..color = leafDark);

    // Ledger spine down the middle.
    final spinePaint = Paint()
      ..color = spineColor
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy - r * 0.82),
      Offset(cx, cy + r * 0.82),
      spinePaint,
    );

    // Faint tally-mark veins fanning off the spine, like ledger entry ticks.
    final veinPaint = Paint()
      ..color = spineColor.withValues(alpha: 0.45)
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    for (final dy in [-r * 0.3, r * 0.3]) {
      canvas.drawLine(
        Offset(cx - r * 0.5, cy + dy - r * 0.25),
        Offset(cx, cy + dy),
        veinPaint,
      );
      canvas.drawLine(
        Offset(cx + r * 0.5, cy + dy - r * 0.25),
        Offset(cx, cy + dy),
        veinPaint,
      );
    }

    // Amber harvest dot, upper-right.
    canvas.drawCircle(
      Offset(cx + r * 0.62, cy - r * 0.62),
      r * 0.16,
      Paint()..color = harvestDot,
    );
  }

  @override
  bool shouldRepaint(covariant _MandiMarkPainter oldDelegate) {
    return oldDelegate.leafLight != leafLight ||
        oldDelegate.leafDark != leafDark ||
        oldDelegate.spineColor != spineColor ||
        oldDelegate.harvestDot != harvestDot;
  }
}