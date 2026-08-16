import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/vehicle_model.dart';

class WizardReviewStep extends StatelessWidget {
  final int groupCount;
  final String? productName;
  final List<Map<String, dynamic>> Function(int g) purchasesForGroup;
  final double Function(int g) groupQuantityKg;
  final double Function(int g) groupPurchaseCost;
  final double Function(int g) groupPaidAmount;
  final List<String> Function(int g) groupSuppliers;
  final String Function(int g) groupPaymentMode;
  final double Function(int g) groupPackingCost;
  final double Function(int g) groupExpenseCost;
  final double Function(int g) groupDailyCharges;
  final double Function(int g) groupLoadCost;
  final List<Map<String, dynamic>> Function(int g) loadsForGroup;
  final List<Map<String, dynamic>> Function(int g) packingForGroup;
  final List<Map<String, dynamic>> Function(int g) partnersForGroup;
  final List<VehicleModel> vehicles;

  const WizardReviewStep({
    super.key,
    required this.groupCount,
    required this.productName,
    required this.purchasesForGroup,
    required this.groupQuantityKg,
    required this.groupPurchaseCost,
    required this.groupPaidAmount,
    required this.groupSuppliers,
    required this.groupPaymentMode,
    required this.groupPackingCost,
    required this.groupExpenseCost,
    required this.groupDailyCharges,
    required this.groupLoadCost,
    required this.loadsForGroup,
    required this.packingForGroup,
    required this.partnersForGroup,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = [for (var g = 1; g <= groupCount; g++) g];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in groups) _groupSummaryCard(theme, g),
          if (groups.length > 1) ...[
            const SizedBox(height: 16),
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
                      '${groups.length} batches will be created. Backend will auto-generate batch codes (GM-YYYY-NNNN) and recompute totals.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ] else
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
                      'Backend will auto-generate a batch code (GM-YYYY-NNNN) and recompute totals.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupSummaryCard(ThemeData theme, int g) {
    final groupPurchases = purchasesForGroup(g);
    final purchaseCost = groupPurchaseCost(g);
    final totalQty = groupQuantityKg(g);
    final paidAmount = groupPaidAmount(g);
    final suppliers = groupSuppliers(g);
    final aggregatePaymentMode = groupPaymentMode(g);
    final packingCost = groupPackingCost(g);
    final expenseCost = groupExpenseCost(g);
    final dailyCharges = groupDailyCharges(g);
    final transportLoadCost = groupLoadCost(g);
    final loads = loadsForGroup(
      g,
    ).where((v) => v['vehicle_id'] != null).toList();
    final vehicleCount = loads.map((v) => v['vehicle_id']).toSet().length;
    final total =
        purchaseCost +
        packingCost +
        expenseCost +
        dailyCharges +
        transportLoadCost;
    final partnerCount = partnersForGroup(
      g,
    ).where((p) => p['partner_id'] != null).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupCount > 1 ? 'Batch $g' : 'Summary',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _summaryRow('Product', productName ?? '-'),
          _summaryRow('Quantity', '${totalQty.toStringAsFixed(1)} kg'),
          _summaryRow(
            'Supplier',
            suppliers.isEmpty ? '-' : suppliers.join(', '),
          ),
          if (groupPurchases.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...groupPurchases.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p['supplierName'] as String? ?? '-',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${(p['kgTotal'] as num?)?.toStringAsFixed(1) ?? '0'} kg × ${CurrencyFormatter.format((p['lineCost'] as num?)?.toDouble())}',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _summaryRow(
            'Purchase payment',
            aggregatePaymentMode == 'cash'
                ? 'Cash'
                : aggregatePaymentMode == 'credit'
                ? 'Credit'
                : 'Part cash / credit',
          ),
          if (paidAmount > 0)
            _summaryRow('Paid now', CurrencyFormatter.format(paidAmount)),
          _summaryRow('Purchase cost', CurrencyFormatter.format(purchaseCost)),
          _summaryRow('Partners', '$partnerCount'),
          _summaryRow('Daily charges', CurrencyFormatter.format(dailyCharges)),
          _summaryRow('Packing', CurrencyFormatter.format(packingCost)),
          _summaryRow('Expenses', CurrencyFormatter.format(expenseCost)),
          if (loads.isNotEmpty) ...[
            _summaryRow('Vehicles', '$vehicleCount'),
            _summaryRow('Loads', '${loads.length}'),
            const SizedBox(height: 6),
            ...loads.asMap().entries.map(
              (entry) => _loadRow(theme, g, entry.key, entry.value),
            ),
            const SizedBox(height: 6),
          ],
          _summaryRow(
            'Transport loads',
            CurrencyFormatter.format(transportLoadCost),
          ),
          const Divider(height: 24),
          _summaryRow(
            'Total estimated cost',
            CurrencyFormatter.format(total),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _loadRow(
    ThemeData theme,
    int g,
    int index,
    Map<String, dynamic> load,
  ) {
    final plate = _vehiclePlate(load['vehicle_id'] as String?);
    final label = _packingLabelFor(g, load['packing_index'] as int?);
    final units = double.tryParse(load['unit_count'].toString()) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Load ${index + 1} · $plate'
              '${label != null ? ' — $label' : ''}',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${units.toStringAsFixed(0)} units',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _vehiclePlate(String? vehicleId) {
    if (vehicleId == null) return 'Unassigned';
    final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
    return vehicle?.plateNumber ?? 'Unknown vehicle';
  }

  String? _packingLabelFor(int g, int? packingIndex) {
    if (packingIndex == null) return null;
    final packing = packingForGroup(g);
    if (packingIndex < 0 || packingIndex >= packing.length) return null;
    final p = packing[packingIndex];
    final unitType = p['unit_type'] as String? ?? '';
    final count = (p['unit_count'] as num?)?.toInt() ?? 0;
    final label = p['unit_label'] as String?;
    if (unitType == 'custom') {
      return label == null || label.isEmpty ? 'Loose' : label;
    }
    return '$unitType × $count';
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
