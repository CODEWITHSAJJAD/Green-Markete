import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../app_dropdown.dart';
import 'wizard_group_selector.dart';

class WizardTransportStep extends StatefulWidget {
  final int groupCount;
  final int activeGroup;
  final ValueChanged<int> onGroupSelected;
  final List<Map<String, dynamic>> loadsForActiveGroup;
  final List<Map<String, dynamic>> packingForActiveGroup;
  final ValueChanged<List<Map<String, dynamic>>> onLoadsChanged;

  const WizardTransportStep({
    super.key,
    required this.groupCount,
    required this.activeGroup,
    required this.onGroupSelected,
    required this.loadsForActiveGroup,
    required this.packingForActiveGroup,
    required this.onLoadsChanged,
  });

  @override
  State<WizardTransportStep> createState() => _WizardTransportStepState();
}

class _WizardTransportStepState extends State<WizardTransportStep> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final loads = widget.loadsForActiveGroup;
    final packing = widget.packingForActiveGroup;
    final totalPackedUnits = packing.fold<int>(
      0,
      (a, p) => a + ((p['unit_count'] as num?)?.toInt() ?? 0),
    );
    final totalLoadedUnits = loads.fold<double>(
      0,
      (a, l) => a + (double.tryParse(l['unit_count'].toString()) ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizardGroupSelector(
            groupCount: widget.groupCount,
            activeGroup: widget.activeGroup,
            onGroupSelected: widget.onGroupSelected,
          ),
          Text(
            'Split the batch across vehicles. Linked loads split shared transport fairly between packing records.',
            style: theme.textTheme.bodyMedium,
          ),
          if (totalPackedUnits > 0) ...[
            const SizedBox(height: 8),
            Text(
              totalLoadedUnits <= 0
                  ? '$totalPackedUnits units packed — nothing loaded yet.'
                  : '${totalLoadedUnits.toStringAsFixed(0)} of $totalPackedUnits units loaded — ${(totalPackedUnits - totalLoadedUnits).toStringAsFixed(0)} remaining.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: totalLoadedUnits > totalPackedUnits
                    ? Colors.orange
                    : theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (vehicles.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(MingCuteIcons.mgc_information_line, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No vehicles registered yet. Add them from Manage → Vehicles, or skip this step.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...List.generate(loads.length, (i) {
              final load = loads[i];
              return _transportLoadCard(theme, i, load, vehicles);
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                final next = [
                  ...loads,
                  <String, dynamic>{
                    'vehicle_id': null,
                    'packing_index': null,
                    'unit_count': '0',
                    'cost_type': 'per_vehicle',
                    'transport_cost': '0',
                  },
                ];
                widget.onLoadsChanged(next);
              },
              icon: const Icon(MingCuteIcons.mgc_add_line),
              label: const Text('Add vehicle load'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transportLoadCard(
    ThemeData theme,
    int index,
    Map<String, dynamic> load,
    List<VehicleModel> vehicles,
  ) {
    final packing = widget.packingForActiveGroup;
    final loads = widget.loadsForActiveGroup;
    return Container(
      key: ValueKey('load-$index'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Load ${index + 1}', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(MingCuteIcons.mgc_close_line, size: 18),
                onPressed: () {
                  final next = [...loads];
                  next.removeAt(index);
                  widget.onLoadsChanged(next);
                },
              ),
            ],
          ),
          AppDropdown<VehicleModel>.fromList(
            value: vehicles
                .where((v) => v.id == load['vehicle_id'])
                .firstOrNull,
            items: vehicles,
            itemLabel: (v) => v.plateNumber,
            labelText: 'Vehicle',
            onChanged: (v) {
              setState(() => load['vehicle_id'] = v?.id);
              widget.onLoadsChanged(loads);
            },
          ),
          if (packing.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppDropdown<int?>(
              value: load['packing_index'] as int?,
              labelText: 'Packing record (optional)',
              items: [
                const DropdownItem<int?>(
                  value: null,
                  child: Text('None (general load)'),
                ),
                for (var i = 0; i < packing.length; i++)
                  if (_packingRemaining(i) > 0 || load['packing_index'] == i)
                    DropdownItem<int?>(
                      value: i,
                      child: Text(
                        '${_packingLabel(i)}'
                        '${_packingRemaining(i) > 0 ? ' — ${_packingRemaining(i).toStringAsFixed(0)} left' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
              onChanged: (v) {
                setState(() => load['packing_index'] = v);
                widget.onLoadsChanged(loads);
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            initialValue: load['unit_count'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Units loaded'),
            onChanged: (v) {
              setState(() => load['unit_count'] = v);
              widget.onLoadsChanged(loads);
            },
          ),
          if (load['packing_index'] is int) ...[
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final remaining = _packingRemaining(
                  load['packing_index'] as int,
                );
                return Text(
                  remaining < 0
                      ? 'Overloaded by ${remaining.abs().toStringAsFixed(0)} — exceeds available units'
                      : 'Remaining after this load: ${remaining.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: remaining < 0 ? Colors.orange : Colors.grey,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          AppDropdown<String>(
            value: load['cost_type'] as String?,
            labelText: 'Cost type',
            items: const [
              DropdownItem(
                value: 'per_vehicle',
                child: Text('Flat per vehicle'),
              ),
              DropdownItem(
                value: 'per_packing',
                child: Text('Per unit loaded'),
              ),
              DropdownItem(value: 'lump_sum', child: Text('Lump sum')),
            ],
            onChanged: (v) {
              setState(() => load['cost_type'] = v ?? 'per_vehicle');
              widget.onLoadsChanged(loads);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: load['transport_cost'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: load['cost_type'] == 'per_packing'
                  ? 'Transport cost per unit'
                  : 'Transport cost',
            ),
            onChanged: (v) {
              setState(() => load['transport_cost'] = v);
              widget.onLoadsChanged(loads);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${CurrencyFormatter.format(_loadTotal(load))}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  double _loadTotal(Map<String, dynamic> load) {
    final cost = double.tryParse(load['transport_cost'].toString()) ?? 0;
    final units = double.tryParse(load['unit_count'].toString()) ?? 0;
    return load['cost_type'] == 'per_packing' ? units * cost : cost;
  }

  double _loadedUnitsFor(int packingIndex) {
    var total = 0.0;
    for (final load in widget.loadsForActiveGroup) {
      if (load['packing_index'] == packingIndex) {
        total += double.tryParse(load['unit_count'].toString()) ?? 0;
      }
    }
    return total;
  }

  double _packingRemaining(int packingIndex) {
    final packing = widget.packingForActiveGroup;
    if (packingIndex < 0 || packingIndex >= packing.length) return 0;
    final packed =
        (packing[packingIndex]['unit_count'] as num?)?.toDouble() ?? 0;
    return packed - _loadedUnitsFor(packingIndex);
  }

  String _packingLabel(int index) {
    final packing = widget.packingForActiveGroup;
    if (index < 0 || index >= packing.length) return '—';
    final p = packing[index];
    final unitType = p['unit_type'] as String? ?? '';
    final count = (p['unit_count'] as num?)?.toInt() ?? 0;
    final label = p['unit_label'] as String?;
    if (unitType == 'custom') {
      final weight = (p['packed_kg'] as num?)?.toDouble() ?? 0;
      final name = label == null || label.isEmpty ? 'Loose' : label;
      return '${index + 1}. $name'
          '${weight > 0 ? ' (${weight.toStringAsFixed(1)} kg)' : ''}';
    }
    return '${index + 1}. $unitType × $count';
  }
}
