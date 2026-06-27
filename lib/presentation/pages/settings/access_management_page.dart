import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/theme.dart';

class AccessManagementPage extends ConsumerWidget {
  const AccessManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample users for now; will be fetched from backend
    final users = [
      _UserEntry('Ahmed Khan', 'ahmed@example.com', 'admin', true),
      _UserEntry('Sara Ali', 'sara@example.com', 'manager', true),
      _UserEntry('Usman Raza', 'usman@example.com', 'sales', true),
      _UserEntry('Fatima Noor', 'fatima@example.com', 'viewer', false),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Access Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.person_add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.name[0],
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: user.isActive ? AppColors.success : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  color: user.isActive ? AppColors.success : Colors.grey,
                  size: 18,
                ),
              ],
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _UserEntry {
  final String name;
  final String email;
  final String role;
  final bool isActive;
  const _UserEntry(this.name, this.email, this.role, this.isActive);
}
