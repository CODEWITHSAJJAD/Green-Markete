import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/unit_converter.dart';
import '../../../data/models/market_model.dart';
import '../../../data/models/product_model.dart';
import '../../providers/market_provider.dart';
import '../../providers/measurement_unit_provider.dart';
import '../../providers/product_provider.dart';
import '../app_dropdown.dart';
import '../purchase_entry_form.dart';

class WizardBasicInfoStep extends StatelessWidget {
  final String? productId;
  final String? productName;
  final String? sourceMarketId;
  final String? destinationMarketId;
  final DateTime purchaseDate;
  final List<Map<String, dynamic>> purchases;
  final String transportPaidBy;
  final List<String> suppliers;
  final void Function(String id, String name) onProductChanged;
  final ValueChanged<String?> onSourceMarketChanged;
  final ValueChanged<String?> onDestinationMarketChanged;
  final ValueChanged<DateTime> onPurchaseDateChanged;
  final ValueChanged<List<Map<String, dynamic>>> onPurchasesChanged;
  final ValueChanged<String> onTransportPaidByChanged;
  final Future<void> Function(String name) onCreateSupplier;

  const WizardBasicInfoStep({
    super.key,
    required this.productId,
    required this.productName,
    required this.sourceMarketId,
    required this.destinationMarketId,
    required this.purchaseDate,
    required this.purchases,
    required this.transportPaidBy,
    required this.suppliers,
    required this.onProductChanged,
    required this.onSourceMarketChanged,
    required this.onDestinationMarketChanged,
    required this.onPurchaseDateChanged,
    required this.onPurchasesChanged,
    required this.onTransportPaidByChanged,
    required this.onCreateSupplier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsProvider = context.watch<ProductProvider>();
    final marketsProvider = context.watch<MarketProvider>();
    final customUnits = context
        .watch<MeasurementUnitProvider>()
        .units
        .map((u) => PurchaseUnit(u.id, u.name, u.kgPerUnit))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product & Market', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _productDropdown(theme, productsProvider.products),
          const SizedBox(height: 12),
          _marketDropdown(theme, marketsProvider.markets, isSource: true),
          const SizedBox(height: 12),
          _marketDropdown(theme, marketsProvider.markets, isSource: false),
          const SizedBox(height: 16),
          Text('Purchase Date', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: purchaseDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                onPurchaseDateChanged(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(MingCuteIcons.mgc_calendar_3_line, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${purchaseDate.year}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Purchases', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add purchases from one or more suppliers. Each line has its own unit, market and payment mode.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          PurchaseEntryForm(
            entries: purchases,
            markets: marketsProvider.markets,
            suppliers: suppliers,
            onChanged: onPurchasesChanged,
            onCreateSupplier: onCreateSupplier,
            customUnits: customUnits,
          ),
          const SizedBox(height: 16),
          Text('Transport Paid By', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'purchaser', label: Text('Purchaser')),
              ButtonSegment(value: 'seller', label: Text('Seller')),
            ],
            selected: {transportPaidBy},
            onSelectionChanged: (v) => onTransportPaidByChanged(v.first),
          ),
        ],
      ),
    );
  }

  Widget _productDropdown(ThemeData theme, List<ProductModel> products) {
    return AppDropdown<ProductModel>.fromList(
      value: products.where((p) => p.id == productId).firstOrNull,
      items: products,
      itemLabel: (p) => p.name,
      labelText: 'Select product',
      onChanged: (p) {
        if (p != null) {
          onProductChanged(p.id, p.name);
        }
      },
    );
  }

  Widget _marketDropdown(
    ThemeData theme,
    List<MarketModel> markets, {
    required bool isSource,
  }) {
    final selectedId = isSource ? sourceMarketId : destinationMarketId;
    return AppDropdown<MarketModel>.fromList(
      value: markets.where((m) => m.id == selectedId).firstOrNull,
      items: markets,
      itemLabel: (m) => '${m.name} • ${m.city}',
      labelText: isSource ? 'Source market' : 'Destination market',
      onChanged: (m) {
        if (isSource) {
          onSourceMarketChanged(m?.id);
        } else {
          onDestinationMarketChanged(m?.id);
        }
      },
    );
  }
}
