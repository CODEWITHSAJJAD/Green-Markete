import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PackingEntryForm extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const PackingEntryForm({
    super.key,
    required this.entries,
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
    _emit();
  }

  Map<String, dynamic> _empty() => {
    'unit_type': 'bag',
    'unit_label': null,
    'unit_count': 0,
    'cost_per_unit': 0.0,
  };

  void _emit() => widget.onChanged(List<Map<String, dynamic>>.from(_entries));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
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
                          labelText: 'Unit Type',
                        ),
                        items: const [
                          DropdownItem(value: 'bag', child: Text('Bag')),
                          DropdownItem(value: 'packet', child: Text('Packet')),
                          DropdownItem(value: 'crate', child: Text('Crate')),
                          DropdownItem(value: 'box', child: Text('Box')),
                          DropdownItem(value: 'custom', child: Text('Custom')),
                        ],
                        onChanged: (v) {
                          setState(() => _entries[i]['unit_type'] = v ?? 'bag');
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
                if ((_entries[i]['unit_count'] as int) > 0 &&
                    (_entries[i]['cost_per_unit'] as double) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Subtotal: PKR ${((_entries[i]['unit_count'] as int) * (_entries[i]['cost_per_unit'] as double)).toStringAsFixed(0)}',
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
}
