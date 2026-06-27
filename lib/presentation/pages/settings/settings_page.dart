import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle: authState.user?.fullName ?? 'Update your profile',
            onTap: () => context.go('/settings/profile'),
          ),
          _SettingsTile(
            icon: Icons.business,
            title: 'Business Settings',
            subtitle: 'Company info and preferences',
            onTap: () => context.go('/settings/business'),
          ),
          _SettingsTile(
            icon: Icons.admin_panel_settings,
            title: 'Access Management',
            subtitle: 'Manage users and permissions',
            onTap: () => context.go('/settings/access'),
          ),
          const Divider(indent: 16, endIndent: 16),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const Divider(indent: 16, endIndent: 16),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: '',
            textColor: AppColors.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (textColor ?? AppColors.primary).withOpacity(0.1),
        child: Icon(icon, color: textColor ?? AppColors.primary),
      ),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
