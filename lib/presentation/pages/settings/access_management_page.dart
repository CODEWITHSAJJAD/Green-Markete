import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/partner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/app_dropdown.dart';

class AccessManagementPage extends StatefulWidget {
  const AccessManagementPage({super.key});

  @override
  State<AccessManagementPage> createState() => _AccessManagementPageState();
}

class _AccessManagementPageState extends State<AccessManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<AuthProvider>().businessId ?? '';
      context.read<PartnerProvider>().load(businessId);
    });
  }

  Future<void> _update(
    PartnerModel partner,
    String businessId,
    String? accessLevel,
  ) async {
    if (accessLevel == null) return;
    await context.read<PartnerProvider>().updateAccess(
      partner.id,
      accessLevel,
      businessId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final provider = context.watch<PartnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Access Management')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text(provider.error!))
          : provider.partners.isEmpty
          ? const Center(child: Text('No partners found'))
          : _buildList(provider.partners, businessId),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner.fullName, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(partner.role, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: AppDropdown<String>(
                    value: access,
                    items: _roleItems(access),
                    onChanged: (value) => _update(partner, businessId, value),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<DropdownItem<String>> _roleItems(String current) {
    const selectable = ['viewer', 'editor'];
    final options = selectable.contains(current)
        ? selectable
        : [...selectable, current];
    return [
      for (final option in options)
        DropdownItem(
          value: option,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_roleIcon(option), size: 16, color: _roleColor(option)),
              const SizedBox(width: 8),
              Text(_roleLabel(option)),
            ],
          ),
        ),
    ];
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'owner':
        return MingCuteIcons.mgc_medal_line;
      case 'editor':
        return MingCuteIcons.mgc_edit_2_line;
      default:
        return MingCuteIcons.mgc_eye_line;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return const Color(0xFF8B5CF6);
      case 'editor':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'editor':
        return 'Editor';
      default:
        return 'Viewer';
    }
  }
}
