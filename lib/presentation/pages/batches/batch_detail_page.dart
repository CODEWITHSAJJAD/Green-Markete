import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/theme.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../providers/data_refresh.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/batches/batch_dialogs.dart';
import '../../widgets/batches/batch_expenses_tab.dart';
import '../../widgets/batches/batch_overview_tab.dart';
import '../../widgets/batches/batch_packing_tab.dart';
import '../../widgets/batches/batch_pl_tab.dart';
import '../../widgets/batches/batch_returns_tab.dart';
import '../../widgets/batches/batch_sales_tab.dart';
import '../../widgets/batches/batch_settlements_tab.dart';
import '../../widgets/batches/batch_transport_tab.dart';
import '../../widgets/expense_entry_sheet.dart';
import '../../widgets/sale_entry_sheet.dart';
import 'batch_pl_page.dart';

class BatchDetailPage extends StatefulWidget {
  final String batchId;

  const BatchDetailPage({super.key, required this.batchId});

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  String get batchId => widget.batchId;

  RealtimeChannel? _expensesChannel;
  RealtimeChannel? _salesChannel;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 8, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    DataRefreshNotifier.instance.addListener(_onSharedRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  void _loadAll() {
    if (!mounted) return;
    final detail = context.read<BatchDetailProvider>();
    final pl = context.read<BatchPLProvider>();
    final expenses = context.read<ExpenseProvider>();
    final sales = context.read<SaleProvider>();
    detail.load(batchId);
    pl.load(batchId);
    expenses.load(batchId);
    sales.loadByBatch(batchId);
    _subscribeRealtime(detail, pl, expenses, sales);
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<PartnerProvider>().load(businessId);
    }
  }

  void _onSharedRefresh() {
    if (!mounted) return;
    context.read<BatchDetailProvider>().load(batchId);
    context.read<BatchPLProvider>().load(batchId);
    context.read<ExpenseProvider>().load(batchId);
    context.read<SaleProvider>().loadByBatch(batchId);
  }

  void _subscribeRealtime(
    BatchDetailProvider detail,
    BatchPLProvider pl,
    ExpenseProvider expenses,
    SaleProvider sales,
  ) {
    final client = SupabaseService.instance.client;
    _expensesChannel = client
        .channel('expenses_batch_$batchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            expenses.load(batchId);
            pl.load(batchId);
            detail.load(batchId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            expenses.load(batchId);
            pl.load(batchId);
            detail.load(batchId);
          },
        )
        .subscribe();

    _salesChannel = client
        .channel('sales_batch_$batchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sales',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            sales.loadByBatch(batchId);
            pl.load(batchId);
            detail.load(batchId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sales',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'batch_id',
            value: batchId,
          ),
          callback: (_) {
            sales.loadByBatch(batchId);
            pl.load(batchId);
            detail.load(batchId);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    DataRefreshNotifier.instance.removeListener(_onSharedRefresh);
    _tabCtrl.dispose();
    if (_expensesChannel != null) {
      SupabaseService.instance.client.removeChannel(_expensesChannel!);
    }
    if (_salesChannel != null) {
      SupabaseService.instance.client.removeChannel(_salesChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchProvider = context.watch<BatchDetailProvider>();
    final batch = batchProvider.batch;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          batch?.productName ?? 'Batch Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profit & Loss Statement',
            icon: const Icon(HeroIcons.presentation_chart_bar, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BatchPLPage(batchId: batchId),
              ),
            ),
          ),
          if (batch != null &&
              batch.status != 'closed' &&
              context.watch<AuthProvider>().capabilities.can(Capability.closeBatch))
            IconButton(
              tooltip: 'Close Batch',
              icon: const Icon(HeroIcons.archive_box, size: 20),
              onPressed: () => confirmCloseBatch(context, batchId),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Packing'),
            Tab(text: 'Returns'),
            Tab(text: 'Expenses'),
            Tab(text: 'Transport'),
            Tab(text: 'Sales'),
            Tab(text: 'Settlement'),
            Tab(text: 'P&L'),
          ],
        ),
      ),
      body: _buildBody(context, batchProvider),
      floatingActionButton: batch?.status != 'closed'
          ? _buildFab(context)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    BatchDetailProvider batchProvider,
  ) {
    final batch = batchProvider.batch;
    if (batch == null) {
      if (batchProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (batchProvider.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                const SizedBox(height: 12),
                Text(batchProvider.error!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () =>
                      context.read<BatchDetailProvider>().load(batchId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: Text('No batch data found'));
    }
    return TabBarView(
      controller: _tabCtrl,
      children: [
        BatchOverviewTab(batch: batch),
        BatchPackingTab(batch: batch),
        BatchReturnsTab(batch: batch),
        BatchExpensesTab(batch: batch),
        BatchTransportTab(batch: batch),
        BatchSalesTab(batch: batch),
        BatchSettlementsTab(batch: batch),
        const BatchPLTab(),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final canPurchaser = auth.canEditPurchaserSide;
    final canSeller = auth.canEditSellerSide;
    final tabIndex = _tabCtrl.index;
    if (tabIndex == 1) {
      if (!canPurchaser) return const SizedBox.shrink();
      return FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => showAddPackingDialog(context, batchId),
        icon: const Icon(HeroIcons.plus, size: 18),
        label: const Text('Packing'),
      );
    }
    if (tabIndex == 2) {
      if (!canPurchaser) return const SizedBox.shrink();
      return FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => showAddReturnDialog(context, batchId),
        icon: const Icon(HeroIcons.arrow_uturn_left, size: 18),
        label: const Text('Return'),
      );
    }
    if (tabIndex == 3) {
      final allowed = [
        if (canPurchaser) 'purchaser',
        if (canSeller) 'seller',
        if (auth.capabilities.can(Capability.addExpense) &&
            auth.capabilities.isAccountant) ...['purchaser', 'seller'],
      ];
      if (allowed.isEmpty) return const SizedBox.shrink();
      return FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await showExpenseEntrySheet(
            context,
            batchId: batchId,
            allowedSides: allowed,
          );
          if (!context.mounted) return;
          context.read<ExpenseProvider>().load(batchId);
          context.read<BatchPLProvider>().load(batchId);
          context.read<BatchDetailProvider>().load(batchId);
        },
        icon: const Icon(HeroIcons.plus, size: 18),
        label: const Text('Expense'),
      );
    }
    if (tabIndex == 4) {
      if (!canPurchaser) return const SizedBox.shrink();
      return FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => showAddTransportDialog(context, batchId),
        icon: const Icon(HeroIcons.truck, size: 18),
        label: const Text('Transport'),
      );
    }
    if (tabIndex == 5) {
      if (!canSeller) return const SizedBox.shrink();
      final batch = context.read<BatchDetailProvider>().batch;
      if (batch == null) return const SizedBox.shrink();
      final soldQuantity = context.read<SaleProvider>().sales.fold<double>(
        0,
        (acc, s) => acc + s.quantitySold,
      );
      return FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final saved = await showSaleEntrySheet(
            context,
            batch: batch,
            soldQuantity: soldQuantity,
          );
          if (!context.mounted) return;
          context.read<SaleProvider>().loadByBatch(batchId);
          context.read<BatchPLProvider>().load(batchId);
          context.read<BatchDetailProvider>().load(batchId);
          if (saved == true) {
            final businessId = context.read<AuthProvider>().businessId;
            if (businessId != null && businessId.isNotEmpty) {
              DataRefreshNotifier.instance.refresh(businessId);
            }
          }
        },
        icon: const Icon(HeroIcons.plus, size: 18),
        label: const Text('Record Sale'),
      );
    }
    return const SizedBox.shrink();
  }
}
