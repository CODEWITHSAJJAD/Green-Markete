import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import 'batch_dialogs.dart';
import 'batch_metric_card.dart';

class BatchSalesTab extends StatelessWidget {
  final BatchModel batch;

  const BatchSalesTab({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saleProvider = context.watch<SaleProvider>();
    if (saleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (saleProvider.error != null) {
      return Center(child: Text(saleProvider.error!));
    }
    final sales = saleProvider.sales;
    if (sales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No sales yet. Tap + to record a sale.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    final totalQty = sales.fold<double>(0, (acc, s) => acc + s.quantitySold);
    final totalRev = sales.fold<double>(0, (acc, s) => acc + s.totalAmount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Sold',
                  '${totalQty.toStringAsFixed(0)} ${batch.unit}',
                ),
              ),
              Expanded(
                child: buildBatchMetric(
                  theme,
                  'Revenue',
                  CurrencyFormatter.format(totalRev),
                ),
              ),
            ],
          ),
        ),
        ...sales.map((s) => _saleTile(context, s, batch.unit)),
      ],
    );
  }

  Widget _saleTile(BuildContext context, SaleModel sale, String unit) {
    final theme = Theme.of(context);
    final walkInCredit = sale.customerId == null && sale.creditAmount > 0;
    final canCollect =
        walkInCredit && context.read<AuthProvider>().canEditSellerSide;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: getPaymentModeColor(
          theme,
          sale.paymentMode,
        ).withValues(alpha: 0.15),
        child: Icon(
          getPaymentModeIcon(sale.paymentMode),
          color: getPaymentModeColor(theme, sale.paymentMode),
          size: 18,
        ),
      ),
      title: Text(
        '${sale.quantitySold.toStringAsFixed(0)} $unit × ${CurrencyFormatter.format(sale.pricePerUnit)}',
      ),
      subtitle: Text(
        [
          '${sale.saleDate} • ${sale.paymentMode}',
          if (walkInCredit)
            'Walk-in credit left: ${CurrencyFormatter.format(sale.creditAmount)}',
        ].join('\n'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.format(sale.totalAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Roboto Mono',
            ),
          ),
          if (canCollect) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Collect walk-in credit',
              visualDensity: VisualDensity.compact,
              onPressed: () => showCollectWalkInCreditDialog(context, sale),
              icon: const Icon(MingCuteIcons.mgc_cash_line, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
