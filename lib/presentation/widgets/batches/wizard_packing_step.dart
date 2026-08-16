import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/unit_converter.dart';
import '../../providers/packing_type_provider.dart';
import '../packing_entry_form.dart';
import 'wizard_group_selector.dart';

class WizardPackingStep extends StatelessWidget {
  final int groupCount;
  final int activeGroup;
  final ValueChanged<int> onGroupSelected;
  final List<Map<String, dynamic>> packingForActiveGroup;
  final double groupQuantityKg;
  final ValueChanged<List<Map<String, dynamic>>> onPackingChanged;

  const WizardPackingStep({
    super.key,
    required this.groupCount,
    required this.activeGroup,
    required this.onGroupSelected,
    required this.packingForActiveGroup,
    required this.groupQuantityKg,
    required this.onPackingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final customPackingTypes = context
        .watch<PackingTypeProvider>()
        .types
        .map((t) => PackingType(t.id, t.name, t.kgCapacity))
        .toList();
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
          const Text(
            'Add packing records (optional). Total cost = count × cost per unit.',
          ),
          const SizedBox(height: 16),
          PackingEntryForm(
            key: ValueKey('packing-$activeGroup'),
            entries: packingForActiveGroup,
            totalKg: groupQuantityKg,
            onChanged: onPackingChanged,
            customPackingTypes: customPackingTypes,
          ),
        ],
      ),
    );
  }
}
