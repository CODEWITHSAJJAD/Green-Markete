class PurchaseUnit {
  final String key;
  final String label;
  final double kgPerUnit;

  const PurchaseUnit(this.key, this.label, this.kgPerUnit);
}

const purchaseUnits = <PurchaseUnit>[
  PurchaseUnit('kg', 'kg', 1),
  PurchaseUnit('g', 'gram (g)', 0.001),
  PurchaseUnit('mann', 'Mann (40 kg)', 40),
  PurchaseUnit('bag_5', '5 kg bag', 5),
  PurchaseUnit('bag_10', '10 kg bag', 10),
  PurchaseUnit('bag_60', '60 kg bag', 60),
  PurchaseUnit('bag_100', '100 kg bag', 100),
  PurchaseUnit('crate_15', 'Crate (15 kg)', 15),
  PurchaseUnit('crate_20', 'Crate (20 kg)', 20),
];

PurchaseUnit purchaseUnitByKey(String key) {
  final match = purchaseUnits.where((u) => u.key == key);
  if (match.isNotEmpty) return match.first;
  return const PurchaseUnit('kg', 'kg', 1);
}

class PackingType {
  final String key;
  final String label;
  final double kgCapacity;

  const PackingType(this.key, this.label, this.kgCapacity);
}

const customPackingType = PackingType('custom', 'Custom packing (loose)', 0);

const packingTypes = <PackingType>[
  PackingType('bag_5', 'Plastic bag (5 kg)', 5),
  PackingType('bag_60', '60 kg bag', 60),
  PackingType('bag_100', '100 kg bag', 100),
  PackingType('crate_15', 'Plastic crate (15 kg)', 15),
  PackingType('crate_20', 'Plastic crate (20 kg)', 20),
  customPackingType,
];

PackingType packingTypeByKey(String key) {
  final match = packingTypes.where((p) => p.key == key);
  if (match.isNotEmpty) return match.first;
  return const PackingType('bag_5', 'Plastic bag (5 kg)', 5);
}

class PackingSuggestion {
  final PackingType type;
  final int count;

  /// Exact kg for a `custom` packing suggestion (the leftover weight).
  final double? customKg;

  const PackingSuggestion(this.type, this.count, {this.customKg});
}

List<PackingSuggestion> suggestPackingBreakdown(double totalKg) {
  if (totalKg <= 0) return const [];
  final fixed = packingTypes
      .where((p) => p.kgCapacity > 0)
      .toList()
    ..sort((a, b) => b.kgCapacity.compareTo(a.kgCapacity));

  final suggestions = <PackingSuggestion>[];
  var remaining = totalKg;
  for (final type in fixed) {
    if (remaining <= 0.01) break;
    final count = (remaining ~/ type.kgCapacity);
    if (count > 0) {
      suggestions.add(PackingSuggestion(type, count));
      remaining -= count * type.kgCapacity;
    }
  }
  if (remaining > 0.01) {
    suggestions.add(
      PackingSuggestion(customPackingType, 1, customKg: remaining),
    );
  }
  return suggestions;
}
