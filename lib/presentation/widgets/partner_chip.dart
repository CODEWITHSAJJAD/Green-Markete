import 'package:flutter/material.dart';

class PartnerChip extends StatelessWidget {
  final String name;
  final String? role;
  final Color? color;

  const PartnerChip({
    super.key,
    required this.name,
    this.role,
    this.color,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.green.shade700;
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: chipColor,
        radius: 14,
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      label: Text(
        role != null ? '$name ($role)' : name,
        style: const TextStyle(fontSize: 13),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
