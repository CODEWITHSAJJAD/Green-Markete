import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(child: ListTile(title: const Text('Full Name'), subtitle: Text(user?.fullName ?? '-'))),
          Card(child: ListTile(title: const Text('Email'), subtitle: Text(user?.email ?? '-'))),
          Card(child: ListTile(title: const Text('Phone'), subtitle: Text(user?.phone ?? '-'))),
          Card(child: ListTile(title: const Text('City'), subtitle: Text(user?.city ?? '-'))),
          Card(child: ListTile(title: const Text('Role'), subtitle: Text(user?.role ?? '-'))),
        ],
      ),
    );
  }
}
