import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../core/utils/unit_converter.dart';
import 'app_dropdown.dart';

class PackingEntryForm extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final double? totalKg;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const PackingEntryForm({
    super.key,
    required this.entries,
    required this.totalKg,
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
  }

  Map<String, dynamic> _empty() => <String, dynamic>{
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
          .map((s) => <String, dynamic>{
            'unit_type': s.type.key,
            'unit_label': s.customKg != null
                ? 'Loose / ${s.customKg!.toStringAsFixed(1)} kg'
                : s.type.label,
            'unit_count': s.count,
            'cost_per_unit': 0.0,
            if (s.customKg != null) 'packed_kg': s.customKg,
          })
          .toList();
    });
    _emit();
  }

  double get _packedKg => _entries.fold<double>(0, (acc, e) {
    final stored = (e['packed_kg'] as num?)?.toDouble() ?? 0;
    if (stored > 0) return acc + stored;
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
          _PackingEntryCard(
            key: ValueKey('pack-$i'),
            index: i,
            entry: _entries[i],
            deletable: _entries.length > 1,
            onChanged: (next) {
              _entries[i] = Map<String, dynamic>.from(next);
              _emit();
            },
            onDelete: () {
              setState(() => _entries.removeAt(i));
              _emit();
            },
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

  Widget _summaryRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackingEntryCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> entry;
  final bool deletable;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const _PackingEntryCard({
    super.key,
    required this.index,
    required this.entry,
    required this.deletable,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_PackingEntryCard> createState() => _PackingEntryCardState();
}

class _PackingEntryCardState extends State<_PackingEntryCard> {
  late String _unitType;
  late final ValueNotifier<String> _unitTypeNotifier;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _countCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _customKgCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _unitType = (e['unit_type'] as String?) ?? 'bag_5';
    _unitTypeNotifier = ValueNotifier(_unitType);
    _labelCtrl = TextEditingController(text: e['unit_label']?.toString() ?? '');
    _countCtrl = TextEditingController(text: (e['unit_count'] as num?)?.toString() ?? '0');
    _costCtrl = TextEditingController(text: (e['cost_per_unit'] as num?)?.toString() ?? '0');
    _customKgCtrl = TextEditingController(
      text: (e['packed_kg'] as num?)?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _unitTypeNotifier.dispose();
    _labelCtrl.dispose();
    _countCtrl.dispose();
    _costCtrl.dispose();
    _customKgCtrl.dispose();
    super.dispose();
  }

  bool get _isCustom => _unitType == 'custom';

  Map<String, dynamic> _buildPayload() {
    final type = packingTypeByKey(_unitType);
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0.0;
    final weight = _isCustom
        ? double.tryParse(_customKgCtrl.text) ?? 0.0
        : type.kgCapacity * count;
    return <String, dynamic>{
      'unit_type': _unitType,
      'unit_label': _isCustom
          ? (_labelCtrl.text.isEmpty
              ? 'Loose / ${weight.toStringAsFixed(1)} kg'
              : _labelCtrl.text)
          : (_labelCtrl.text.isEmpty ? null : _labelCtrl.text),
      'unit_count': count,
      'cost_per_unit': cost,
      'packed_kg': weight,
      'subtotal': cost * count,
    };
  }

  void _emit() => widget.onChanged({...widget.entry, ..._buildPayload()});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0.0;
    final weight = _isCustom
        ? double.tryParse(_customKgCtrl.text) ?? 0.0
        : packingTypeByKey(_unitType).kgCapacity * count;
    final subtotal = cost * count;

    return Container(
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
                child: AppDropdown<String>(
                  value: _unitType,
                  labelText: 'Packing type',
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
                    if (v == null) return;
                    _unitType = v;
                    _unitTypeNotifier.value = v;
                    setState(() {});
                    _emit();
                  },
                ),
              ),
              if (widget.deletable)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
          if (_isCustom) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customKgCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Loose weight (kg)',
                hintText: 'Enter the remaining weight',
              ),
              onChanged: (_) {
                setState(() {});
                _emit();
              },
            ),
          ],
          const SizedBox(height: 8),
          TextFormField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: _isCustom
                  ? 'Unit label (optional)'
                  : 'Unit label (optional)',
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isCustom ? 'Count (lots)' : 'Count',
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost per unit',
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _emit();
                  },
                ),
              ),
            ],
          ),
          if (count > 0 || weight > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _summary(weight, subtotal),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _summary(double weight, double subtotal) {
    final parts = <String>[];
    if (weight > 0) parts.add('${weight.toStringAsFixed(1)} kg');
    if (subtotal > 0) parts.add('PKR ${subtotal.toStringAsFixed(0)}');
    return parts.join(' · ');
  }
}