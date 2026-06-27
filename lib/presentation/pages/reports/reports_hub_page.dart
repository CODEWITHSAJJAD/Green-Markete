import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme.dart';

class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _ReportCard(
              icon: Icons.assessment,
              title: 'P&L Summary',
              subtitle: 'Business profit & loss',
              color: AppColors.primary,
              onTap: () => context.go('/reports/pl'),
            ),
            _ReportCard(
              icon: Icons.credit_score,
              title: 'Customer Credit',
              subtitle: 'Outstanding balances',
              color: AppColors.secondary,
              onTap: () => context.go('/reports/credit'),
            ),
            _ReportCard(
              icon: Icons.person,
              title: 'Partner Report',
              subtitle: 'Partner-specific P&L',
              color: Colors.blue,
              onTap: () {},
            ),
            _ReportCard(
              icon: Icons.store,
              title: 'Market Performance',
              subtitle: 'By city & market',
              color: Colors.teal,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
