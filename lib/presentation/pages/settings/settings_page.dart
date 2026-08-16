import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
import 'about_page.dart';
import 'access_management_page.dart';
import 'audit_log_page.dart';
import 'business_settings_page.dart';
import 'business_switcher_page.dart';
import 'help_center_page.dart';
import 'notification_settings_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>();
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GreenCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.fullName?.isNotEmpty == true ? user!.fullName![0] : 'U').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Text(
                    (user?.role ?? 'Owner').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Business & Team Management'),
          const SizedBox(height: 8),
          _settingTile(
            HeroIcons.user_circle,
            'Personal Profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          _settingTile(
            HeroIcons.building_office_2,
            'Business Profile & Info',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessSettingsPage()),
            ),
          ),
          _settingTile(
            HeroIcons.arrows_right_left,
            'Switch / Add Enterprise Business',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessSwitcherPage()),
            ),
          ),
          _settingTile(
            HeroIcons.shield_check,
            'Access Control & Roles Matrix',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccessManagementPage()),
            ),
          ),
          if (user?.role == 'owner')
            _settingTile(
              HeroIcons.clock,
              'System Audit Logs',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuditLogPage()),
              ),
            ),
          _settingTile(
            HeroIcons.bell,
            'Push & Alert Notifications',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Help & Knowledge Base'),
          const SizedBox(height: 8),
          _settingTile(
            HeroIcons.question_mark_circle,
            'Help & Documentation',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpCenterPage()),
            ),
          ),
          _settingTile(
            HeroIcons.information_circle,
            'About Green Market',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(HeroIcons.arrow_left_on_rectangle, size: 19, color: AppColors.rose),
              label: Text(
                'Sign Out of Session',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.rose,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.rose, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, {VoidCallback? onTap}) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          HeroIcons.chevron_right,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
