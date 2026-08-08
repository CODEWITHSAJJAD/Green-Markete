import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class BatchSummaryCard extends StatelessWidget {
  final String productName;
  final String? batchCode;
  final String sourceCity;
  final String destinationCity;
  final String status;
  final String quantity;
  final double totalCost;
  final double totalRevenue;
  final double netProfitLoss;

  const BatchSummaryCard({
    super.key,
    required this.productName,
    this.batchCode,
    required this.sourceCity,
    required this.destinationCity,
    required this.status,
    required this.quantity,
    required this.totalCost,
    required this.totalRevenue,
    required this.netProfitLoss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: theme.textTheme.titleLarge),
                    if (batchCode != null) Text(batchCode!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _statusPill(theme, status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text('$sourceCity → $destinationCity', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Quantity: $quantity', style: theme.textTheme.bodySmall),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _metric(theme, 'Cost', CurrencyFormatter.format(totalCost))),
              const SizedBox(width: 8),
              Expanded(child: _metric(theme, 'Revenue', CurrencyFormatter.format(totalRevenue))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Net ${netProfitLoss >= 0 ? 'Profit' : 'Loss'}: ${CurrencyFormatter.format(netProfitLoss)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: netProfitLoss >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(ThemeData theme, String status) {
    Color color;
    switch (status) {
      case 'purchased': color = Colors.grey; break;
      case 'packed': color = Colors.blue; break;
      case 'in_transit': color = Colors.amber.shade700; break;
      case 'delivered': color = Colors.green; break;
      case 'selling': color = Colors.teal; break;
      case 'closed': color = Colors.grey.shade800; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _metric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}