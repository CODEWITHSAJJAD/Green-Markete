import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/unit_converter.dart';
import '../../data/models/market_model.dart';

class PurchaseEntryForm extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final List<MarketModel>? markets;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const PurchaseEntryForm({
    super.key,
    required this.entries,
    this.markets,
    required this.onChanged,
  });

  @override
  State<PurchaseEntryForm> createState() => _PurchaseEntryFormState();
}

class _PurchaseEntryFormState extends State<PurchaseEntryForm> {
  late List<Map<String, dynamic>> _entries;
  int _uidSeq = 0;

  @override
  void initState() {
    super.initState();
    _entries = widget.entries.isEmpty ? [_empty()] : List.from(widget.entries);
  }

  Map<String, dynamic> _empty() => {
    'uid': _uidSeq++,
    'supplierName': '',
    'marketId': null,
    'unitKey': 'kg',
    'customKg': '',
    'quantity': 0.0,
    'pricePerUnit': 0.0,
    'paymentMode': 'cash',
    'amountPaid': 0.0,
    'batchGroup': 1,
  };

  void _emit() =>
      widget.onChanged(List<Map<String, dynamic>>.from(_entries));

  double _entryKg(Map<String, dynamic> e) {
    final qty = (e['quantity'] as num?)?.toDouble() ?? 0;
    final unitKey = e['unitKey'] as String? ?? 'kg';
    final kgPerUnit = unitKey == 'custom'
        ? double.tryParse(e['customKg']?.toString() ?? '') ?? 0
        : purchaseUnitByKey(unitKey).kgPerUnit;
    return qty * kgPerUnit;
  }

  double _entryCost(Map<String, dynamic> e) =>
      ((e['quantity'] as num?)?.toDouble() ?? 0) *
      ((e['pricePerUnit'] as num?)?.toDouble() ?? 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalKg = _entries.fold<double>(0, (s, e) => s + _entryKg(e));
    final totalCost = _entries.fold<double>(0, (s, e) => s + _entryCost(e));
    final totalPaid = _entries.fold<double>(
        0, (s, e) => s + ((e['amountPaid'] as num?)?.toDouble() ?? 0));
    final remaining = totalCost - totalPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _entries.length; i++)
          _EntryCard(
            key: ObjectKey(_entries[i]['uid'] ?? i),
            index: i,
            entry: _entries[i],
            markets: widget.markets,
            deletable: _entries.length > 1,
            onChanged: (entry) {
              setState(() => _entries[i] = entry);
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
            label: const Text('Add supplier'),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Purchase Summary',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _summaryRow('Total Weight',
                  '${_fmt(totalKg)} kg (${_entries.length} ${_entries.length == 1 ? 'supplier' : 'suppliers'})'),
              _summaryRow('Total Cost', CurrencyFormatter.format(totalCost)),
              _summaryRow('Total Paid', CurrencyFormatter.format(totalPaid)),
              _summaryRow('Remaining', CurrencyFormatter.format(remaining)),
              if (_groupCount > 1) ...[
                const Divider(height: 20),
                Text('Per batch (kg)', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                for (var g = 1; g <= _groupCount; g++)
                  _summaryRow(
                    'Batch $g',
                    '${_fmt(_entries.where((e) => (e['batchGroup'] as int?) == g).fold<double>(0, (s, e) => s + _entryKg(e)))} kg',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int get _groupCount {
    var max = 1;
    for (final e in _entries) {
      final g = (e['batchGroup'] as int?) ?? 1;
      if (g > max) max = g;
    }
    return max;
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600)),
      ],
    ),
  );

  String _fmt(double v) => v.toStringAsFixed(1);
}

class _EntryCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> entry;
  final List<MarketModel>? markets;
  final bool deletable;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const _EntryCard({
    super.key,
    required this.index,
    required this.entry,
    this.markets,
    required this.deletable,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _customKgCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _paidCtrl;
  late String _unitKey;
  String? _marketId;
  String _paymentMode = 'cash';
  int _batchGroup = 1;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _supplierCtrl = TextEditingController(text: e['supplierName']?.toString());
    _customKgCtrl =
        TextEditingController(text: e['customKg']?.toString() ?? '');
    _qtyCtrl = TextEditingController(text: (e['quantity'] as num?)?.toString());
    _priceCtrl =
        TextEditingController(text: (e['pricePerUnit'] as num?)?.toString());
    _paidCtrl =
        TextEditingController(text: (e['amountPaid'] as num?)?.toString());
    _unitKey = e['unitKey'] as String? ?? 'kg';
    _marketId = e['marketId'] as String?;
    _paymentMode = e['paymentMode'] as String? ?? 'cash';
    _batchGroup = (e['batchGroup'] as int?) ?? 1;
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _customKgCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _snapshot() {
    final unitKey = _unitKey;
    final kgPerUnit = unitKey == 'custom'
        ? double.tryParse(_customKgCtrl.text) ?? 0
        : purchaseUnitByKey(unitKey).kgPerUnit;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    return {
      'uid': widget.entry['uid'] ?? 0,
      'supplierName': _supplierCtrl.text.trim(),
      'marketId': _marketId,
      'unitKey': unitKey,
      'unitLabel': unitKey == 'custom'
          ? 'custom'
          : purchaseUnitByKey(unitKey).label,
      'unitKg': kgPerUnit,
      'customKg': _customKgCtrl.text.trim(),
      'quantity': qty,
      'pricePerUnit': price,
      'paymentMode': _paymentMode,
      'amountPaid': double.tryParse(_paidCtrl.text) ?? 0,
      'kgTotal': qty * kgPerUnit,
      'lineCost': qty * price,
      'batchGroup': _batchGroup,
    };
  }

  void _update(void Function() mutate) {
    mutate();
    widget.onChanged(_snapshot());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitKey = _unitKey;
    final kgPerUnit = unitKey == 'custom'
        ? double.tryParse(_customKgCtrl.text) ?? 0
        : purchaseUnitByKey(unitKey).kgPerUnit;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final subtotal = qty * price;
    final lineKg = qty * kgPerUnit;

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
                child: Text('Supplier ${widget.index + 1}',
                    style: theme.textTheme.titleSmall),
              ),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField2<int>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(_batchGroup),
                  decoration: const InputDecoration(
                    labelText: 'Batch',
                    isDense: true,
                  ),
                  items: [
                    for (var g = 1; g <= 6; g++)
                      DropdownItem(value: g, child: Text('Batch $g')),
                  ],
                  onChanged: (v) =>
                      _update(() => _batchGroup = v ?? 1),
                ),
              ),
              if (widget.deletable)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _supplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Supplier / shop name *',
            ),
            onChanged: (_) => _update(() {}),
          ),
          const SizedBox(height: 12),
          if (widget.markets != null && widget.markets!.isNotEmpty)
            DropdownButtonFormField2<String>(
              isExpanded: true,
              valueListenable: ValueNotifier(_marketId),
              hint: const Text('Market (optional)'),
              decoration: const InputDecoration(labelText: 'Market'),
              items: [
                for (final m in widget.markets!)
                  DropdownItem(
                    value: m.id,
                    child: Text('${m.name} (${m.city})'),
                  ),
              ],
              onChanged: (v) => _update(() => _marketId = v),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField2<String>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(unitKey),
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    for (final u in purchaseUnits)
                      DropdownItem(value: u.key, child: Text(u.label)),
                    const DropdownItem(
                        value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (v) => _update(() => _unitKey = v ?? 'kg'),
                ),
              ),
            ],
          ),
          if (unitKey == 'custom') ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customKgCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(
                labelText: 'Custom weight per unit (kg) *',
              ),
              onChanged: (_) => _update(() {}),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Quantity (${kgPerUnit == 1 ? 'kg' : 'units'})',
                  ),
                  onChanged: (_) => _update(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price per unit',
                  ),
                  onChanged: (_) => _update(() {}),
                ),
              ),
            ],
          ),
          if (lineKg > 0 || subtotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_fmt(lineKg)} kg · ${CurrencyFormatter.format(subtotal)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField2<String>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(_paymentMode),
                  decoration: const InputDecoration(
                    labelText: 'Payment mode',
                  ),
                  items: [
                    for (final m in _paymentModes)
                      DropdownItem(value: m, child: Text(m.replaceAll('_', ' '))),
                  ],
                  onChanged: (v) =>
                      _update(() => _paymentMode = v ?? 'cash'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _paidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount paid'),
                  onChanged: (_) => _update(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _paymentModes = [
    'cash',
    'bank_transfer',
    'debt',
    'credit',
    'pdc',
    'part_credit',
  ];

  String _fmt(double v) => v.toStringAsFixed(1);
}
