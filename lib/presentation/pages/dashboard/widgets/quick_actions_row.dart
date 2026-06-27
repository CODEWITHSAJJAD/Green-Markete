import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.add_box,
            label: 'New Batch',
            color: Colors.green,
            onTap: () => context.go('/batches/new'),
          ),
          _ActionButton(
            icon: Icons.point_of_sale,
            label: 'New Sale',
            color: Colors.teal,
            onTap: () => context.go('/sales/new'),
          ),
          _ActionButton(
            icon: Icons.payments,
            label: 'Payment',
            color: Colors.amber.shade700,
            onTap: () {}, // Navigate to record payment
          ),
          _ActionButton(
            icon: Icons.assessment,
            label: 'Reports',
            color: Colors.blue,
            onTap: () => context.go('/reports'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
