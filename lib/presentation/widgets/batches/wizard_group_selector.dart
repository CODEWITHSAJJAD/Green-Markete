import 'package:flutter/material.dart';

class WizardGroupSelector extends StatelessWidget {
  final int groupCount;
  final int activeGroup;
  final ValueChanged<int> onGroupSelected;

  const WizardGroupSelector({
    super.key,
    required this.groupCount,
    required this.activeGroup,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (groupCount <= 1) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch group (split purchases into separate batches)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var g = 1; g <= groupCount; g++)
              ChoiceChip(
                label: Text('Batch $g'),
                selected: activeGroup == g,
                onSelected: (_) => onGroupSelected(g),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
