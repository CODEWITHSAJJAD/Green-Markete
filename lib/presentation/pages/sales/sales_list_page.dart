import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/batches/batch_dialogs.dart';
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
    DataRefreshNotifier.instance.addListener(_onSharedRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    DataRefreshNotifier.instance.removeListener(_onSharedRefresh);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSharedRefresh() {
    if (mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      await Future.wait([
        context.read<SellingBatchesProvider>().load(
          businessId,
          status: 'selling',
        ),
        context.read<SaleProvider>().loadByBusiness(businessId),
        context.read<CustomerProvider>().load(businessId),
      ]);
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuickSalePage()));
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

    final totalRevenue = allSales.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    final totalCredit = allSales.fold<double>(
      0,
      (sum, s) => sum + s.creditAmount,
    );
    final totalCash = allSales.fold<double>(
      0,
      (sum, s) => sum + s.cashReceived,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Sales & Revenue Ledger',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(HeroIcons.bars_3_bottom_left),
          onPressed: widget.onMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(HeroIcons.arrow_path, size: 20),
            onPressed: _load,
            tooltip: 'Refresh sales',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            _heroSummary(
              theme,
              totalRevenue,
              totalCash,
              totalCredit,
              allSales.length,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _activeTab == 0
                    ? 'Search sales by Customer, mode, or notes...'
                    : 'Search ready batches by code or product...',
                prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(HeroIcons.x_circle, size: 18),
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
                    avatar: Icon(
                      HeroIcons.clock,
                      size: 16,
                      color: _activeTab == 0
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    label: Text('Sales History (${allSales.length})'),
                    selected: _activeTab == 0,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: _activeTab == 0
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: _activeTab == 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _activeTab == 0
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 1,
                      ),
                    ),
                    onSelected: (_) => setState(() => _activeTab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    avatar: Icon(
                      HeroIcons.cube,
                      size: 16,
                      color: _activeTab == 1
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    label: Text('Ready Batches (${sellingBatches.length})'),
                    selected: _activeTab == 1,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: _activeTab == 1
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: _activeTab == 1
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _activeTab == 1
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 1,
                      ),
                    ),
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
                      Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                      const SizedBox(height: 12),
                      Text(saleProvider.error!, textAlign: TextAlign.center),
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
                    icon: HeroIcons.shopping_cart,
                    title: query.isNotEmpty
                        ? 'No matching sales found'
                        : 'No sales recorded yet',
                    subtitle: query.isNotEmpty
                        ? 'Try a different search query.'
                        : 'Record your first wholesale sale against ready batches.',
                    actionLabel: canSell ? 'Record Sale' : null,
                    onAction: canSell ? _openCreate : null,
                  ),
                )
              else
                Column(
                  children: filteredSales.map((sale) {
                    final customerName =
                        customerMap[sale.customerId] ?? 'Direct Customer';
                    return _saleCard(theme, sale, customerName, canSell);
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
                      Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                      const SizedBox(height: 12),
                      Text(batchesProvider.error!, textAlign: TextAlign.center),
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
                    icon: HeroIcons.cube,
                    title: query.isNotEmpty
                        ? 'No matching ready batches'
                        : 'No batches ready for selling',
                    subtitle: query.isNotEmpty
                        ? 'Try modifying your search query.'
                        : 'Advance your delivered batches to "selling" status to start recording wholesale orders.',
                  ),
                )
              else
                Column(
                  children: filteredBatches.map((batch) {
                    return GreenCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.emerald.withValues(
                                  alpha: 0.25,
                                ),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              HeroIcons.shopping_bag,
                              size: 22,
                              color: AppColors.emerald,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  batch.productName ?? batch.batchCode,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Batch #${batch.batchCode} • ${batch.totalQuantity.toStringAsFixed(0)} ${batch.quantityUnit} available',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canSell)
                            FilledButton.tonal(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QuickSalePage(
                                    preselectedBatchId: batch.id,
                                  ),
                                ),
                              ),
                              child: const Text('Sell'),
                            ),
                        ],
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
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: _openCreate,
              icon: const Icon(HeroIcons.plus, size: 18),
              label: Text(
                'Record Sale',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }

  Widget _saleCard(
    ThemeData theme,
    SaleModel sale,
    String customerName,
    bool canSell,
  ) {
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.tryParse(sale.saleDate) ?? DateTime.now());
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: const Icon(
                  HeroIcons.document_text,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(sale.totalAmount),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: AppColors.textPrimary,
                ),
              ),
              if (canSell) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(
                    HeroIcons.ellipsis_vertical,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 120),
                  onSelected: (action) {
                    if (action == 'edit') {
                      showEditSaleDialog(context, sale);
                    } else if (action == 'delete') {
                      showDeleteSaleDialog(context, sale);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            HeroIcons.pencil_square,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            HeroIcons.trash,
                            size: 16,
                            color: AppColors.rose,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.rose),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sale.quantitySold.toStringAsFixed(sale.quantitySold.truncateToDouble() == sale.quantitySold ? 0 : 1)} units @ ${CurrencyFormatter.format(sale.pricePerUnit)}/unit',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                ),
                child: Text(
                  sale.paymentMode.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (isCredit || isCash) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCash)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Cash: ${CurrencyFormatter.format(sale.cashReceived)}',
                          style: GoogleFonts.inter(
                            color: AppColors.emeraldDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (isCredit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.roseSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.rose.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Credit Due: ${CurrencyFormatter.format(sale.creditAmount)}',
                          style: GoogleFonts.inter(
                            color: AppColors.rose,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isCredit && canSell)
                  InkWell(
                    onTap: () => showCollectCreditDialog(
                      context,
                      sale,
                      customerName: customerName != 'Direct Customer'
                          ? customerName
                          : null,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            HeroIcons.banknotes,
                            size: 14,
                            color: AppColors.emeraldDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Collect Cash',
                            style: GoogleFonts.inter(
                              color: AppColors.emeraldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amberSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  HeroIcons.banknotes,
                  size: 22,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Gross Sales',
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$salesCount Orders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Collected',
                        style: GoogleFonts.inter(
                          color: AppColors.emeraldDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(totalCash),
                        style: GoogleFonts.inter(
                          color: AppColors.emeraldDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.roseSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.rose.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Due',
                        style: GoogleFonts.inter(
                          color: AppColors.rose,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(totalCredit),
                        style: GoogleFonts.inter(
                          color: AppColors.rose,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
