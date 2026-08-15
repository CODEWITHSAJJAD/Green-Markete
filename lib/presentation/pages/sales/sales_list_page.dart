import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'quick_sale_page.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final _searchCtrl = TextEditingController();
  int _activeTab = 0; // 0 = Sales History, 1 = Ready-to-sell Batches

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<SellingBatchesProvider>().load(businessId, status: 'selling');
      context.read<SaleProvider>().loadByBusiness(businessId);
      context.read<CustomerProvider>().load(businessId);
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickSalePage()),
    );
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSell = context.watch<AuthProvider>().canEditSellerSide;
    final batchesProvider = context.watch<SellingBatchesProvider>();
    final saleProvider = context.watch<SaleProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    final sellingBatches = batchesProvider.batches;
    final allSales = saleProvider.sales;
    final customers = customerProvider.customers;
    final customerMap = {for (final c in customers) c.id: c.fullName};

    final query = _searchCtrl.text.trim().toLowerCase();

    final filteredSales = query.isEmpty
        ? allSales
        : allSales.where((s) {
            final custName = (customerMap[s.customerId] ?? '').toLowerCase();
            final paymentMode = s.paymentMode.toLowerCase();
            final notes = (s.notes ?? '').toLowerCase();
            final dateStr = s.saleDate.toLowerCase();
            return custName.contains(query) ||
                paymentMode.contains(query) ||
                notes.contains(query) ||
                dateStr.contains(query);
          }).toList();

    final filteredBatches = query.isEmpty
        ? sellingBatches
        : sellingBatches.where((b) {
            final code = b.batchCode.toLowerCase();
            final prod = (b.productName ?? '').toLowerCase();
            return code.contains(query) || prod.contains(query);
          }).toList();

    final totalRevenue = allSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final totalCredit = allSales.fold<double>(0, (sum, s) => sum + s.creditAmount);
    final totalCash = allSales.fold<double>(0, (sum, s) => sum + s.cashReceived);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Revenue'),
        leading: IconButton(
          icon: const Icon(MingCuteIcons.mgc_menu_line),
          onPressed: widget.onMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(MingCuteIcons.mgc_refresh_1_line),
            onPressed: _load,
            tooltip: 'Refresh sales',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _heroSummary(theme, totalRevenue, totalCash, totalCredit, allSales.length),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _activeTab == 0
                    ? 'Search sales by customer, mode, or notes'
                    : 'Search ready batches by code or product',
                prefixIcon: const Icon(MingCuteIcons.mgc_search_2_line),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(MingCuteIcons.mgc_close_line),
                        onPressed: () => setState(() => _searchCtrl.clear()),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(MingCuteIcons.mgc_history_line, size: 16),
                    label: Text('Sales History (${allSales.length})'),
                    selected: _activeTab == 0,
                    onSelected: (_) => setState(() => _activeTab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(MingCuteIcons.mgc_shopping_bag_2_line, size: 16),
                    label: Text('Ready Batches (${sellingBatches.length})'),
                    selected: _activeTab == 1,
                    onSelected: (_) => setState(() => _activeTab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_activeTab == 0) ...[
              if (saleProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (saleProvider.error != null)
                GreenCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(MingCuteIcons.mgc_wifi_off_line, size: 44, color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(saleProvider.error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (filteredSales.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(
                    icon: MingCuteIcons.mgc_bill_line,
                    title: query.isNotEmpty ? 'No matching sales found' : 'No sales recorded yet',
                    subtitle: query.isNotEmpty
                        ? 'Try a different search query.'
                        : 'Record your first sale against active batches.',
                    actionLabel: canSell ? 'Record Sale' : null,
                    onAction: canSell ? _openCreate : null,
                  ),
                )
              else
                Column(
                  children: filteredSales.map((sale) {
                    final customerName = customerMap[sale.customerId] ?? 'Direct Customer';
                    return _saleCard(theme, sale, customerName);
                  }).toList(),
                ),
            ] else ...[
              if (batchesProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (batchesProvider.error != null)
                GreenCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(MingCuteIcons.mgc_wifi_off_line, size: 44, color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(batchesProvider.error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (filteredBatches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(
                    icon: MingCuteIcons.mgc_shopping_bag_2_line,
                    title: query.isNotEmpty ? 'No matching batches' : 'No batches ready for sale',
                    subtitle: 'Advance a batch status to "selling" to record sales against it.',
                  ),
                )
              else
                Column(
                  children: filteredBatches.map((batch) {
                    return GreenCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(MingCuteIcons.mgc_shopping_bag_2_line, size: 22, color: AppColors.secondary),
                        ),
                        title: Text(batch.productName ?? batch.batchCode, style: theme.textTheme.titleMedium),
                        subtitle: Text('Batch: ${batch.batchCode}'),
                        trailing: canSell
                            ? FilledButton.icon(
                                icon: const Icon(MingCuteIcons.mgc_add_line, size: 16),
                                label: const Text('Sell'),
                                onPressed: _openCreate,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: canSell
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _openCreate,
              icon: const Icon(MingCuteIcons.mgc_add_line),
              label: const Text('Record Sale'),
            )
          : null,
    );
  }

  Widget _saleCard(ThemeData theme, SaleModel sale, String customerName) {
    String formattedDate = sale.saleDate;
    try {
      final dt = DateTime.parse(sale.saleDate);
      formattedDate = DateFormat('MMM d, yyyy · h:mm a').format(dt);
    } catch (_) {}

    final isCredit = sale.creditAmount > 0;
    final isCash = sale.cashReceived > 0;

    return GreenCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(MingCuteIcons.mgc_bill_line, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(sale.totalAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sale.quantitySold.toStringAsFixed(sale.quantitySold.truncateToDouble() == sale.quantitySold ? 0 : 1)} units @ ${CurrencyFormatter.format(sale.pricePerUnit)}/unit',
                style: theme.textTheme.bodyMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sale.paymentMode.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (isCredit || isCash) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (isCash)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Cash: ${CurrencyFormatter.format(sale.cashReceived)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isCredit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Due Credit: ${CurrencyFormatter.format(sale.creditAmount)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${sale.notes}',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroSummary(
    ThemeData theme,
    double totalRevenue,
    double totalCash,
    double totalCredit,
    int salesCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.12),
            AppColors.amberSurface.withValues(alpha: 0.7),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(MingCuteIcons.mgc_bill_line, size: 24, color: AppColors.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales & Revenue Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('$salesCount sales recorded across batches', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metricBox(theme, 'Total Revenue', CurrencyFormatter.format(totalRevenue), AppColors.secondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(theme, 'Cash Collected', CurrencyFormatter.format(totalCash), AppColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(theme, 'Credit Due', CurrencyFormatter.format(totalCredit), AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
