import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../core/utils/unit_converter.dart';

class PackingEntryForm extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final double? totalKg;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const PackingEntryForm({
    super.key,
    required this.entries,
    this.totalKg,
    required this.onChanged,
  });

  @override
  State<PackingEntryForm> createState() => _PackingEntryFormState();
}

class _PackingEntryFormState extends State<PackingEntryForm> {
  late List<Map<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.entries.isEmpty ? [_empty()] : List.from(widget.entries);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emit();
    });
  }

  Map<String, dynamic> _empty() => {
    'unit_type': 'bag_5',
    'unit_label': null,
    'unit_count': 0,
    'cost_per_unit': 0.0,
  };

  void _emit() => widget.onChanged(List<Map<String, dynamic>>.from(_entries));

  void _suggest() {
    final totalKg = widget.totalKg ?? 0;
    if (totalKg <= 0) return;
    final suggestions = suggestPackingBreakdown(totalKg);
    if (suggestions.isEmpty) return;
    setState(() {
      _entries = suggestions
          .map((s) => {
            'unit_type': s.type.key,
            'unit_label': s.type.label,
            'unit_count': s.count,
            'cost_per_unit': 0.0,
          })
          .toList();
    });
    _emit();
  }

  double get _packedKg => _entries.fold<double>(0, (acc, e) {
    final size = _sizeKg(e['unit_type'] as String);
    final count = (e['unit_count'] as num?)?.toDouble() ?? 0;
    return acc + size * count;
  });

  double _sizeKg(String? unitType) =>
      packingTypeByKey(unitType ?? 'bag_5').kgCapacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalKg = widget.totalKg ?? 0;
    final packedKg = _packedKg;
    final remainingKg = totalKg - packedKg;
    final overQty = remainingKg < -0.001;
    final status = totalKg <= 0
        ? 'Enter purchases first to see packing coverage.'
        : overQty
        ? 'Packed amount exceeds purchased quantity.'
        : '${remainingKg.toStringAsFixed(1)} kg remaining to pack of ${totalKg.toStringAsFixed(1)} kg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalKg > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Packing Coverage', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _summaryRow(
                  'Purchased',
                  '${totalKg.toStringAsFixed(1)} kg',
                ),
                _summaryRow(
                  'Packed',
                  '${packedKg.toStringAsFixed(1)} kg',
                ),
                _summaryRow(
                  'Remaining',
                  '${remainingKg.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overQty
                        ? Colors.orange
                        : remainingKg < 0.001
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _suggest,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Suggest packing breakdown'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < _entries.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField2<String>(
                        isExpanded: true,
                        valueListenable: ValueNotifier(
                          _entries[i]['unit_type'] as String,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Packing type',
                        ),
                        items: [
                          for (final t in packingTypes)
                            DropdownItem(
                              value: t.key,
                              child: Text(
                                t.label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _entries[i]['unit_type'] = v ?? 'bag_5';
                            _entries[i]['unit_label'] =
                                packingTypeByKey(v ?? 'bag_5').label;
                          });
                          _emit();
                        },
                      ),
                    ),
                    if (_entries.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => _entries.removeAt(i));
                          _emit();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _entries[i]['unit_label']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Unit label (optional)',
                  ),
                  onChanged: (v) {
                    _entries[i]['unit_label'] = v.isEmpty ? null : v;
                    _emit();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _entries[i]['unit_count'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Count'),
                        onChanged: (v) {
                          _entries[i]['unit_count'] = int.tryParse(v) ?? 0;
                          _emit();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _entries[i]['cost_per_unit'].toString(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cost per unit',
                        ),
                        onChanged: (v) {
                          _entries[i]['cost_per_unit'] =
                              double.tryParse(v) ?? 0.0;
                          _emit();
                        },
                      ),
                    ),
                  ],
                ),
                if ((_entries[i]['unit_count'] as int) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _entrySummary(i),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _entries.add(_empty()));
              _emit();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add packing type'),
          ),
        ),
      ],
    );
  }

  String _entrySummary(int i) {
    final count = (_entries[i]['unit_count'] as num?)?.toDouble() ?? 0;
    final cost = (_entries[i]['cost_per_unit'] as num?)?.toDouble() ?? 0;
    final size = _sizeKg(_entries[i]['unit_type'] as String);
    final weight = size * count;
    final subtotal = cost * count;
    final parts = <String>[];
    if (weight > 0) parts.add('${weight.toStringAsFixed(1)} kg');
    if (subtotal > 0) parts.add('PKR ${subtotal.toStringAsFixed(0)}');
    return parts.join(' · ');
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
