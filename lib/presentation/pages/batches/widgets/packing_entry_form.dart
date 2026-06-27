import 'package:flutter/material.dart';

class PackingEntryForm extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const PackingEntryForm({
    super.key,
    required this.records,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Packing Records', style: TextStyle(fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: () {
                final newRecords = List<Map<String, dynamic>>.from(records);
                newRecords.add({
                  'unit_type': 'bag',
                  'unit_label': '',
                  'unit_count': 0,
                  'cost_per_unit': 0.0,
                });
                onChanged(newRecords);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Packing'),
            ),
          ],
        ),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No packing records added', style: TextStyle(color: Colors.grey)),
          )
        else
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: record['unit_type'] as String?,
                            decoration: const InputDecoration(labelText: 'Unit Type', isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'bag', child: Text('Bag')),
                              DropdownMenuItem(value: 'packet', child: Text('Packet')),
                              DropdownMenuItem(value: 'crate', child: Text('Crate')),
                              DropdownMenuItem(value: 'custom', child: Text('Custom')),
                            ],
                            onChanged: (v) {
                              final newRecords = List<Map<String, dynamic>>.from(records);
                              newRecords[index] = {...record, 'unit_type': v};
                              onChanged(newRecords);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () {
                            final newRecords = List<Map<String, dynamic>>.from(records)..removeAt(index);
                            onChanged(newRecords);
                          },
                        ),
                      ],
                    ),
                    if (record['unit_type'] == 'custom')
                      TextField(
                        decoration: const InputDecoration(labelText: 'Custom Unit Label', isDense: true),
                        onChanged: (v) {
                          final newRecords = List<Map<String, dynamic>>.from(records);
                          newRecords[index] = {...record, 'unit_label': v};
                          onChanged(newRecords);
                        },
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Count', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final newRecords = List<Map<String, dynamic>>.from(records);
                              newRecords[index] = {...record, 'unit_count': int.tryParse(v) ?? 0};
                              onChanged(newRecords);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Cost/Unit', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final newRecords = List<Map<String, dynamic>>.from(records);
                              newRecords[index] = {...record, 'cost_per_unit': double.tryParse(v) ?? 0};
                              onChanged(newRecords);
                            },
                          ),
                        ),
                      ],
                    ),
                    if ((record['unit_count'] as int? ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Total: PKR ${((record['unit_count'] as int? ?? 0) * (record['cost_per_unit'] as num? ?? 0).toDouble()).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
