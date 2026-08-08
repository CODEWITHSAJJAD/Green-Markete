import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/config/theme.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(MingCuteIcons.mgc_leaf_2_fill, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Green Market', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Vegetable import/export & wholesale management',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'App Information'),
          const SizedBox(height: 4),
          GreenCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _infoTile(theme, 'Publisher', 'Green Market'),
                _infoTile(theme, 'Version', '1.0.0 (build 1)'),
                _infoTile(theme, 'Purpose', 'Track batches, sales, expenses and partner P&L for vegetable wholesale traders.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Privacy'),
          const SizedBox(height: 4),
          GreenCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _infoTile(theme, 'Data storage', 'Your data is stored securely in the cloud and synced to this device.'),
                _infoTile(theme, 'Offline mode', 'Planned. Currently an active connection is required.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 Green Market. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme, String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
      subtitle: Text(value, style: theme.textTheme.bodyMedium),
    );
  }
}
