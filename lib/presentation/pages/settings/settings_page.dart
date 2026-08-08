import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
import 'access_management_page.dart';
import 'about_page.dart';
import 'business_settings_page.dart';
import 'business_switcher_page.dart';
import 'help_center_page.dart';
import 'notification_settings_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthProvider>();
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (user?.fullName?.isNotEmpty == true ? user!.fullName![0] : 'U').toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'User', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(user?.email ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 4),
          _settingTile(theme, MingCuteIcons.mgc_user_1_line, 'Edit Profile', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()))),
          _settingTile(theme, MingCuteIcons.mgc_building_2_line, 'Business Info', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessSettingsPage()))),
          _settingTile(theme, MingCuteIcons.mgc_store_2_line, 'Switch / Add Business', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusinessSwitcherPage()))),
          _settingTile(theme, MingCuteIcons.mgc_shield_line, 'Access Management', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccessManagementPage()))),
          _settingTile(theme, MingCuteIcons.mgc_notification_line, 'Notifications', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsPage()))),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Support'),
          const SizedBox(height: 4),
          _settingTile(theme, MingCuteIcons.mgc_question_line, 'Help Center', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpCenterPage()))),
          _settingTile(theme, MingCuteIcons.mgc_information_line, 'About', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()))),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(MingCuteIcons.mgc_exit_door_line, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(ThemeData theme, IconData icon, String title, {VoidCallback? onTap}) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: Icon(MingCuteIcons.mgc_arrow_right_line, color: AppColors.textTertiary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
