import 'package:flutter/material.dart';

import '../../presentation/widgets/brand_logo.dart';
import 'bill_model.dart';

/// Renders a [BillModel] as a widget. Used both for on-screen preview and as
/// the source of the PNG image capture (share as image).
class BillView extends StatelessWidget {
  final BillModel bill;

  const BillView({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F5E3B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brand(theme),
          const SizedBox(height: 12),
          Text(
            bill.documentTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12422B),
            ),
          ),
          if (bill.businessName != null && bill.businessName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              bill.businessName!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555E58),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFE2E8E2)),
          const SizedBox(height: 10),
          for (final line in bill.header)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7570),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      line.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A231E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFE2E8E2)),
          const SizedBox(height: 10),
          for (final section in bill.sections) ...[
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF12422B),
              ),
            ),
            const SizedBox(height: 6),
            for (final line in section.lines) _billLine(theme, line),
            const SizedBox(height: 10),
          ],
          if (bill.total != null) ...[
            Container(height: 1, color: const Color(0xFF12422B)),
            const SizedBox(height: 8),
            _billLine(theme, bill.total!, strong: true),
            const SizedBox(height: 8),
            Container(height: 1, color: const Color(0xFF12422B)),
          ],
          if (bill.footer != null && bill.footer!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bill.footer!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7570)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _brand(ThemeData theme) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandLogo(size: 28, isDarkBackground: true),
        SizedBox(width: 10),
        Text(
          'MANDI ROZNAMCHA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _billLine(ThemeData theme, BillLine line, {bool strong = false}) {
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: (strong || line.emphasize) ? FontWeight.w800 : FontWeight.w600,
      color: const Color(0xFF232B26),
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: (strong || line.emphasize) ? FontWeight.w800 : FontWeight.w700,
      color: (strong || line.emphasize) ? const Color(0xFF12422B) : const Color(0xFF1A231E),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(line.label, style: labelStyle)),
              const SizedBox(width: 8),
              Text(line.value, style: valueStyle),
            ],
          ),
          if (line.detail != null && line.detail!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                line.detail!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A948E)),
              ),
            ),
        ],
      ),
    );
  }
}
