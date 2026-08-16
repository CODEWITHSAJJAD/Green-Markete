import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../widgets/brand_logo.dart';
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
          const Center(
            child: BrandLogo(size: 84, isDarkBackground: true),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('MandiRoznamcha', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Wholesale Management Platform',
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
                _infoTile(theme, 'Publisher', 'MandiRoznamcha Technologies'),
                _infoTile(theme, 'Version', '1.0.0 (build 1)'),
                _infoTile(theme, 'Purpose', 'Track batches, sales, expenses and partner P&L for wholesale produce traders.'),
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
              '© 2026 MandiRoznamcha. All rights reserved.',
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
