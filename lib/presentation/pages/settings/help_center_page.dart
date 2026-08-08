import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/config/theme.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Getting Started'),
          const SizedBox(height: 4),
          _faqTile(
            theme,
            'How do I create a batch?',
            'Go to the Batches tab and tap the "New Batch" button. Follow the wizard: pick a product and market, add purchasing partners, then packing and expenses. The batch is saved once you confirm the summary.',
          ),
          _faqTile(
            theme,
            'How do I record a sale?',
            'Open the Sales tab and tap "Record Sale". Sales are tied to batches that are in "selling" status, so move a batch to selling before recording revenue against it.',
          ),
          _faqTile(
            theme,
            'What is a credit alert?',
            'When a customer\'s outstanding balance reaches your business\'s credit alert threshold, they appear in the "Credit alerts" section on the home screen.',
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Data & Reports'),
          const SizedBox(height: 4),
          _faqTile(
            theme,
            'Where do my P&L reports come from?',
            'Open Reports from the sidebar. Batch P&L, business P&L summary, partner performance and credit reports are all computed from your sales, expenses, packing and daily charges.',
          ),
          _faqTile(
            theme,
            'Can I export my reports?',
            'Export is planned for a future build. In the meantime all reports are available on screen.',
          ),
          const SizedBox(height: 8),
          const SectionHeader(title: 'Account & Access'),
          const SizedBox(height: 4),
          _faqTile(
            theme,
            'How do I manage who can edit data?',
            'Open Settings > Access Management. Each partner can be set to Viewer or Editor access. The business owner always keeps full access.',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(MingCuteIcons.mgc_question_line, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Still need help?', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text('Contact support and we\'ll get back to you within 24 hours.', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqTile(ThemeData theme, String question, String answer) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(question, style: theme.textTheme.bodyLarge),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: AppColors.primary,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}
