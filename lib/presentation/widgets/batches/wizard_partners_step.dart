import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/partner_model.dart';
import '../../providers/partner_provider.dart';
import '../app_dropdown.dart';
import '../partner_selector.dart';
import 'wizard_group_selector.dart';

class WizardPartnersStep extends StatelessWidget {
  final int groupCount;
  final int activeGroup;
  final ValueChanged<int> onGroupSelected;
  final String businessId;
  final List<Map<String, dynamic>> partnersForActiveGroup;
  final String? sellerForActiveGroup;
  final ValueChanged<List<Map<String, dynamic>>> onPartnersChanged;
  final ValueChanged<String?> onSellerChanged;

  const WizardPartnersStep({
    super.key,
    required this.groupCount,
    required this.activeGroup,
    required this.onGroupSelected,
    required this.businessId,
    required this.partnersForActiveGroup,
    required this.sellerForActiveGroup,
    required this.onPartnersChanged,
    required this.onSellerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final partners = context.watch<PartnerProvider>().partners;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardGroupSelector(
            groupCount: groupCount,
            activeGroup: activeGroup,
            onGroupSelected: onGroupSelected,
          ),
          const SizedBox(height: 12),
          const Text(
            'Add at least one purchasing partner. Daily charge × days will be added to cost automatically.',
          ),
          const SizedBox(height: 16),
          PartnerSelector(
            key: ValueKey('partners-$activeGroup'),
            selectedPartners: const <PartnerModel>[],
            businessId: businessId,
            onChanged: onPartnersChanged,
          ),
          const SizedBox(height: 24),
          Text(
            'Selling Partner',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          partners.isEmpty
              ? const Text(
                  'No partners yet. Add at least one purchasing partner above first.',
                  style: TextStyle(color: Colors.grey),
                )
              : AppDropdown<PartnerModel>.fromList(
                  value: partners.where((p) => p.id == sellerForActiveGroup).firstOrNull,
                  items: partners,
                  itemLabel: (p) => p.fullName,
                  labelText: 'Select the selling partner',
                  onChanged: (p) => onSellerChanged(p?.id),
                ),
        ],
      ),
    );
  }
}
