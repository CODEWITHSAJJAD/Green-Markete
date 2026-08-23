import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/unit_converter.dart';
import '../../data/models/market_model.dart';
import 'app_dropdown.dart';
import 'supplier_dropdown_field.dart';

class PurchaseEntryForm extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final List<MarketModel>? markets;
  final List<String> suppliers;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  /// Fired when the user creates a brand-new supplier name (via the dropdown's
  /// "Add … as new supplier" row) so it can be persisted to the registry.
  final ValueChanged<String>? onCreateSupplier;

  /// Business-created measurement units (Settings → Units & Packing),
  /// offered in the Purchase Unit dropdown alongside the built-in list.
  final List<PurchaseUnit> customUnits;

  const PurchaseEntryForm({
    super.key,
    required this.entries,
    this.markets,
    this.suppliers = const [],
    required this.onChanged,
    this.onCreateSupplier,
    this.customUnits = const [],
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
    // null = price is quoted per the same unit as the quantity above (the
    // default, unchanged behaviour). Set only when the supplier's price
    // is quoted for a different lot size than what was actually received
    // (e.g. received 50kg loose, but the price known is for a 40kg mann).
    'priceUnitKey': null,
    'priceCustomKg': '',
    'enteredPrice': 0.0,
    'pricePerUnit': 0.0,
    'paymentMode': 'cash',
    'amountPaid': 0.0,
    'batchGroup': 1,
  };

  void _emit() => widget.onChanged(List<Map<String, dynamic>>.from(_entries));

  double _entryKg(Map<String, dynamic> e) {
    final qty = (e['quantity'] as num?)?.toDouble() ?? 0;
    final unitKey = e['unitKey'] as String? ?? 'kg';
    final kgPerUnit = unitKey == 'custom'
        ? double.tryParse(e['customKg']?.toString() ?? '') ?? 0
        : resolvePurchaseUnit(unitKey, widget.customUnits).kgPerUnit;
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
      0,
      (s, e) => s + ((e['amountPaid'] as num?)?.toDouble() ?? 0),
    );
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
            suppliers: widget.suppliers,
            onCreateSupplier: widget.onCreateSupplier,
            customUnits: widget.customUnits,
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
            label: const Text('Add Purchase'),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Purchase Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _summaryRow(
                'Total Weight',
                '${_fmt(totalKg)} kg (${_entries.length} ${_entries.length == 1 ? 'supplier' : 'suppliers'})',
              ),
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
      children: [
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  String _fmt(double v) => v.toStringAsFixed(1);
}

class _EntryCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> entry;
  final List<MarketModel>? markets;
  final List<String> suppliers;
  final bool deletable;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<String>? onCreateSupplier;
  final List<PurchaseUnit> customUnits;

  const _EntryCard({
    super.key,
    required this.index,
    required this.entry,
    this.markets,
    this.suppliers = const [],
    required this.deletable,
    required this.onChanged,
    required this.onDelete,
    this.onCreateSupplier,
    this.customUnits = const [],
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  late final TextEditingController _customKgCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _priceCustomKgCtrl;
  late final TextEditingController _paidCtrl;
  late String _unitKey;
  String? _priceUnitKey;
  String? _marketId;
  String _paymentMode = 'cash';
  int _batchGroup = 1;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _customKgCtrl = TextEditingController(
      text: e['customKg']?.toString() ?? '',
    );
    _qtyCtrl = TextEditingController(text: (e['quantity'] as num?)?.toString());
    _priceCtrl = TextEditingController(
      text: (e['enteredPrice'] as num?)?.toString() ??
          (e['pricePerUnit'] as num?)?.toString(),
    );
    _priceCustomKgCtrl = TextEditingController(
      text: e['priceCustomKg']?.toString() ?? '',
    );
    _paidCtrl = TextEditingController(
      text: (e['amountPaid'] as num?)?.toString(),
    );
    _unitKey = e['unitKey'] as String? ?? 'kg';
    _priceUnitKey = e['priceUnitKey'] as String?;
    _marketId = e['marketId'] as String?;
    _paymentMode = e['paymentMode'] as String? ?? 'cash';
    _batchGroup = (e['batchGroup'] as int?) ?? 1;
  }

  @override
  void dispose() {
    _customKgCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _priceCustomKgCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  double _kgPerUnit(String key, String customText) {
    if (key == 'custom') return double.tryParse(customText) ?? 0;
    return resolvePurchaseUnit(key, widget.customUnits).kgPerUnit;
  }

  /// Price expressed per the QUANTITY unit — the raw entered price when the
  /// price is quoted for the same unit as the quantity (the default,
  /// unchanged behaviour), or converted through kg when the supplier's
  /// price is for a different lot size than what was actually received
  /// (e.g. received 50kg loose, priced per a 40kg mann).
  double _pricePerQuantityUnit() {
    final entered = double.tryParse(_priceCtrl.text) ?? 0;
    final priceUnitKey = _priceUnitKey;
    if (priceUnitKey == null) return entered;
    final priceUnitKg = _kgPerUnit(priceUnitKey, _priceCustomKgCtrl.text);
    final qtyUnitKg = _kgPerUnit(_unitKey, _customKgCtrl.text);
    if (priceUnitKg <= 0 || qtyUnitKg <= 0) return 0;
    return (entered / priceUnitKg) * qtyUnitKg;
  }

  double _effectivePricePerKg() {
    final entered = double.tryParse(_priceCtrl.text) ?? 0;
    final unitKg = _priceUnitKey == null
        ? _kgPerUnit(_unitKey, _customKgCtrl.text)
        : _kgPerUnit(_priceUnitKey!, _priceCustomKgCtrl.text);
    return unitKg > 0 ? entered / unitKg : 0;
  }

  Map<String, dynamic> _snapshot() {
    final unitKey = _unitKey;
    final kgPerUnit = _kgPerUnit(unitKey, _customKgCtrl.text);
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final enteredPrice = double.tryParse(_priceCtrl.text) ?? 0;
    final pricePerQtyUnit = _pricePerQuantityUnit();
    return {
      'uid': widget.entry['uid'] ?? 0,
      'supplierName': (widget.entry['supplierName'] as String? ?? '').trim(),
      'marketId': _marketId,
      'unitKey': unitKey,
      'unitLabel': unitKey == 'custom'
          ? 'custom'
          : resolvePurchaseUnit(unitKey, widget.customUnits).label,
      'unitKg': kgPerUnit,
      'customKg': _customKgCtrl.text.trim(),
      'quantity': qty,
      'priceUnitKey': _priceUnitKey,
      'priceCustomKg': _priceCustomKgCtrl.text.trim(),
      'enteredPrice': enteredPrice,
      'pricePerUnit': pricePerQtyUnit,
      'paymentMode': _paymentMode,
      'amountPaid': double.tryParse(_paidCtrl.text) ?? 0,
      'kgTotal': qty * kgPerUnit,
      'lineCost': qty * pricePerQtyUnit,
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
    final kgPerUnit = _kgPerUnit(unitKey, _customKgCtrl.text);
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = _pricePerQuantityUnit();
    final subtotal = qty * price;
    final lineKg = qty * kgPerUnit;
    final effectivePricePerKg = _effectivePricePerKg();

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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Purchase #${widget.index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.deletable)
                IconButton(
                  icon: const Icon(
                    MingCuteIcons.mgc_delete_3_line,
                    size: 20,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete purchase',
                  onPressed: widget.onDelete,
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppDropdown<int>(
            value: _batchGroup,
            labelText: 'Batch Group',
            prefixIcon: const Icon(MingCuteIcons.mgc_box_3_line, size: 18),
            items: [
              for (var g = 1; g <= 6; g++)
                DropdownItem(value: g, child: Text('Batch $g')),
            ],
            onChanged: (v) => _update(() => _batchGroup = v ?? 1),
          ),
          const SizedBox(height: 12),
          SupplierDropdownField(
            value: (widget.entry['supplierName'] as String?) ?? '',
            suppliers: widget.suppliers,
            onChanged: (v) => _update(() {
              widget.entry['supplierName'] = v;
            }),
            onCreateSupplier: widget.onCreateSupplier,
          ),
          const SizedBox(height: 12),
          if (widget.markets != null && widget.markets!.isNotEmpty)
            AppDropdown<String>(
              value: _marketId,
              labelText: 'Market',
              hintText: 'Market (optional)',
              prefixIcon: const Icon(MingCuteIcons.mgc_location_line, size: 18),
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
                child: TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity Purchased'),
                  onChanged: (_) => _update(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price per unit',
                  ),
                  onChanged: (_) => _update(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Units',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        value: unitKey,
                        labelText: 'Purchase unit',
                        fillColor: theme.colorScheme.surface,
                        items: [
                          for (final u in purchaseUnits)
                            DropdownItem(value: u.key, child: Text(u.label)),
                          for (final u in widget.customUnits)
                            DropdownItem(value: u.key, child: Text(u.label)),
                          const DropdownItem(value: 'custom', child: Text('Custom Weight')),
                        ],
                        onChanged: (v) => _update(() => _unitKey = v ?? 'kg'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppDropdown<String?>(
                        value: _priceUnitKey,
                        labelText: 'Price quoted per',
                        fillColor: theme.colorScheme.surface,
                        items: [
                          const DropdownItem<String?>(
                            value: null,
                            child: Text('Same as purchase unit'),
                          ),
                          for (final u in purchaseUnits)
                            DropdownItem<String?>(value: u.key, child: Text(u.label)),
                          for (final u in widget.customUnits)
                            DropdownItem<String?>(value: u.key, child: Text(u.label)),
                          const DropdownItem<String?>(value: 'custom', child: Text('Custom Weight')),
                        ],
                        onChanged: (v) => _update(() => _priceUnitKey = v),
                      ),
                    ),
                  ],
                ),
                if (unitKey == 'custom') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customKgCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Custom weight per unit (kg) *',
                      filled: false,
                    ),
                    onChanged: (_) => _update(() {}),
                  ),
                ],
                if (_priceUnitKey == 'custom') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceCustomKgCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Lot weight the price covers (kg) *',
                      filled: false,
                    ),
                    onChanged: (_) => _update(() {}),
                  ),
                ],
                if (unitKey != 'kg' || _priceUnitKey != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  if (unitKey != 'kg')
                    _conversionLine(
                      theme,
                      'Weight received',
                      lineKg > 0 ? '${_fmt(lineKg)} kg' : '—',
                    ),
                  if (_priceUnitKey != null)
                    Padding(
                      padding: EdgeInsets.only(top: unitKey != 'kg' ? 4 : 0),
                      child: _conversionLine(
                        theme,
                        'Rate per kg',
                        effectivePricePerKg > 0
                            ? CurrencyFormatter.format(effectivePricePerKg)
                            : '—',
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_fmt(lineKg)} kg',
                  style: theme.textTheme.titleSmall,
                ),
                Flexible(
                  child: Text(
                    CurrencyFormatter.format(subtotal),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  value: _paymentMode,
                  labelText: 'Payment mode',
                  items: [
                    for (final m in _paymentModes)
                      DropdownItem(
                        value: m,
                        child: Text(m.replaceAll('_', ' ')),
                      ),
                  ],
                  onChanged: (v) => _update(() => _paymentMode = v ?? 'cash'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _paidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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

Widget _conversionLine(ThemeData theme, String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: theme.textTheme.bodySmall),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
