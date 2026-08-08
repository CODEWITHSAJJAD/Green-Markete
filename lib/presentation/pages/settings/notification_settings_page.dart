import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/theme.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _creditAlerts = true;
  bool _batchAlerts = true;
  bool _expenseAlerts = false;
  bool _dailyDigest = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _creditAlerts = prefs.getBool('credit_alerts') ?? true;
      _batchAlerts = prefs.getBool('batch_alerts') ?? true;
      _expenseAlerts = prefs.getBool('expense_alerts') ?? false;
      _dailyDigest = prefs.getBool('daily_digest') ?? false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('credit_alerts', _creditAlerts);
    await prefs.setBool('batch_alerts', _batchAlerts);
    await prefs.setBool('expense_alerts', _expenseAlerts);
    await prefs.setBool('daily_digest', _dailyDigest);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Alerts'),
          const SizedBox(height: 4),
          _toggleTile(
            theme,
            MingCuteIcons.mgc_wallet_3_line,
            'Credit alerts',
            'Get notified when a customer crosses the credit threshold.',
            _creditAlerts,
            (v) => setState(() => _creditAlerts = v),
          ),
          _toggleTile(
            theme,
            MingCuteIcons.mgc_shopping_bag_2_line,
            'Batch updates',
            'Batch status changes and new batch activity.',
            _batchAlerts,
            (v) => setState(() => _batchAlerts = v),
          ),
          _toggleTile(
            theme,
            MingCuteIcons.mgc_bill_line,
            'Expense approvals',
            'When a partner or expense needs attention.',
            _expenseAlerts,
            (v) => setState(() => _expenseAlerts = v),
          ),
          _toggleTile(
            theme,
            MingCuteIcons.mgc_notification_line,
            'Daily summary',
            'A daily digest of sales, credit and P&L.',
            _dailyDigest,
            (v) => setState(() => _dailyDigest = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GreenCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        activeThumbColor: AppColors.primary,
        inactiveThumbColor: AppColors.textTertiary,
      ),
    );
  }
}
