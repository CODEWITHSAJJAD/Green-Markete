import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/config/theme.dart';

class BatchSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const BatchSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Batch Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _Row(label: 'Product', value: data['product_name'] as String? ?? '-'),
            _Row(label: 'Quantity', value: '${data['total_quantity'] ?? '-'} ${data['quantity_unit'] ?? ''}'),
            _Row(label: 'Purchase Price', value: CurrencyFormatter.format((data['purchase_price_per_unit'] as num?)?.toDouble() ?? 0)),
            _Row(label: 'Total Purchase Cost', value: CurrencyFormatter.format((data['total_purchase_cost'] as num?)?.toDouble() ?? 0)),
            _Row(label: 'Est. Packing Cost', value: CurrencyFormatter.format((data['total_packing_cost'] as num?)?.toDouble() ?? 0)),
            _Row(label: 'Est. Transport', value: CurrencyFormatter.format((data['transport_cost'] as num?)?.toDouble() ?? 0)),
            const Divider(thickness: 2),
            _Row(
              label: 'Estimated Total Cost',
              value: CurrencyFormatter.format((data['estimated_total'] as num?)?.toDouble() ?? 0),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _Row({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          )),
          Text(value, style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: isBold ? AppColors.primary : null,
          )),
        ],
      ),
    );
  }
}
