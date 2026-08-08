import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/partner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';

class AccessManagementPage extends StatefulWidget {
  const AccessManagementPage({super.key});

  @override
  State<AccessManagementPage> createState() => _AccessManagementPageState();
}

class _AccessManagementPageState extends State<AccessManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    context.read<PartnerProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final partnersProvider = context.watch<PartnerProvider>();
    final businessId = context.watch<AuthProvider>().businessId ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Access Management')),
      body: partnersProvider.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(partnersProvider.error!),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : partnersProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildList(partnersProvider.partners, businessId),
    );
  }

  Widget _buildList(List<PartnerModel> partners, String businessId) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: partners.length,
      itemBuilder: (context, index) {
        final partner = partners[index];
        final access = partner.accessLevel ?? 'viewer';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(partner.fullName),
            subtitle: Text(partner.role),
            trailing: DropdownButton<String>(
              value: access,
              items: const [
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                DropdownMenuItem(value: 'editor', child: Text('Editor')),
              ],
              onChanged: (value) => _update(partner, businessId, value),
            ),
          ),
        );
      },
    );
  }

  Future<void> _update(PartnerModel partner, String businessId, String? value) async {
    if (value == null) return;
    await context.read<PartnerProvider>().updateAccess(partner.id, value, businessId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${partner.fullName} updated to $value')));
    }
  }
}
