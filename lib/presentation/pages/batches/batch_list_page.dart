import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/capability.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../../widgets/status_pill.dart';
import 'batch_detail_page.dart';
import 'create_batch_wizard.dart';

class BatchListPage extends StatefulWidget {
  const BatchListPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  State<BatchListPage> createState() => _BatchListPageState();
}

class _BatchListPageState extends State<BatchListPage> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  bool _selecting = false;
  final Set<String> _selectedIds = {};

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
      context.read<BatchListProvider>().load(businessId);
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateBatchWizard()),
    );
    if (!mounted) return;
    _load();
  }

  bool _canManage() =>
      context.read<AuthProvider>().capabilities.can(Capability.closeBatch);

  void _toggleSelect(String id) {
    if (!_selecting && !_canManage()) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selecting = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelect() {
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  Future<void> _bulkClose() async {
    final ids = _selectedIds.toList();
    final provider = context.read<BatchDetailProvider>();
    int ok = 0;
    for (final id in ids) {
      try {
        await provider.updateStatus('closed', id: id);
        ok++;
      } catch (_) {
        // Continue with the remaining items.
      }
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Marked $ok of ${ids.length} batches as closed')),
    );
    _exitSelect();
    _load();
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      DataRefreshNotifier.instance.refresh(businessId);
    }
  }

  Future<bool> _confirmDeleteBatch(BatchModel batch) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<BatchListProvider>();
    final businessId = context.read<AuthProvider>().businessId;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${batch.productName ?? batch.batchCode}?',
      message:
          'Permanently deletes this batch and all its packing, expenses, sales, transport and purchase records. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return false;
    try {
      await provider.delete(batch.id);
      if (businessId != null && businessId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(businessId);
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted batch ${batch.batchCode}')),
      );
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
      return false;
    }
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedIds.toList();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${ids.length} batches?',
      message:
          'Permanently deletes ${ids.length} selected batches and all their related records. This action cannot be reversed.',
      confirmLabel: 'Delete All',
      isDestructive: true,
    );
    if (ok != true) return;
    final provider = context.read<BatchListProvider>();
    final businessId = context.read<AuthProvider>().businessId;
    int deleted = 0;
    for (final id in ids) {
      try {
        await provider.delete(id);
        deleted++;
      } catch (_) {}
    }
    if (!mounted) return;
    if (businessId != null && businessId.isNotEmpty) {
      DataRefreshNotifier.instance.refresh(businessId);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $deleted of ${ids.length} batches')),
    );
    _exitSelect();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchesProvider = context.watch<BatchListProvider>();
    final allBatches = batchesProvider.batches;
    final isLoading = batchesProvider.isLoading;
    final error = batchesProvider.error;

    final query = _searchCtrl.text.trim().toLowerCase();
    final filteredBatches = allBatches.where((b) {
      if (_statusFilter != 'all' && b.status.toLowerCase() != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final code = b.batchCode.toLowerCase();
      final prod = (b.productName ?? '').toLowerCase();
      final status = b.status.toLowerCase();
      return code.contains(query) || prod.contains(query) || status.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(HeroIcons.x_mark),
                onPressed: _exitSelect,
                tooltip: 'Cancel selection',
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  tooltip: 'Delete selected',
                  onPressed: _selectedIds.isEmpty ? null : _bulkDelete,
                  icon: const Icon(HeroIcons.trash),
                ),
                IconButton(
                  tooltip: 'Mark as closed',
                  onPressed: _selectedIds.isEmpty ? null : _bulkClose,
                  icon: const Icon(HeroIcons.archive_box),
                ),
              ],
            )
          : AppBar(
              title: Text(
                AppLocalizations.of(context)!.batchesScreenTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              leading: IconButton(
                icon: const Icon(HeroIcons.bars_3_bottom_left),
                onPressed: widget.onMenu,
              ),
            ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _load(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
              context.read<BatchListProvider>().loadMore();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              _hero(theme),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search batches by code, produce, or status...',
                  prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(HeroIcons.x_circle, size: 18),
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip('All', 'all'),
                    const SizedBox(width: 8),
                    _statusChip('Selling', 'selling'),
                    const SizedBox(width: 8),
                    _statusChip('In Transit', 'in_transit'),
                    const SizedBox(width: 8),
                    _statusChip('Packing', 'packed'),
                    const SizedBox(width: 8),
                    _statusChip('Purchased', 'purchased'),
                    const SizedBox(width: 8),
                    _statusChip('Closed', 'closed'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                GreenCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        HeroIcons.wifi,
                        size: 44,
                        color: AppColors.rose.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13)),
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
                    title: query.isNotEmpty ? 'No matching batches' : 'No batches in supply chain',
                    subtitle: query.isNotEmpty
                        ? 'Try modifying your search or status filter.'
                        : 'Create your first produce batch to track purchase, packing, transit, and wholesale sales.',
                    actionLabel: query.isEmpty ? 'New Batch' : null,
                    onAction: query.isEmpty ? _openCreate : null,
                  ),
                )
              else ...[
                ...filteredBatches.map((batch) {
                  final isSelected = _selectedIds.contains(batch.id);
                  final card = GreenCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    color: isSelected
                        ? AppColors.primarySurface
                        : null,
                    borderColor: isSelected ? AppColors.primary : null,
                    onTap: _selecting
                        ? () => _toggleSelect(batch.id)
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BatchDetailPage(batchId: batch.id),
                              ),
                            ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (_selecting)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  isSelected
                                      ? HeroIcons.check_circle
                                      : HeroIcons.circle_stack,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              )
                            else
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.divider,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  HeroIcons.cube,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                            SizedBox(width: _selecting ? 0 : 12),
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
                                    '#${batch.batchCode}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusPill(status: batch.status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _meta(
                                theme,
                                'Volume',
                                '${batch.totalQuantity.toStringAsFixed(batch.totalQuantity.truncateToDouble() == batch.totalQuantity ? 0 : 1)} ${batch.quantityUnit}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _meta(
                                theme,
                                'Purchase Cost',
                                CurrencyFormatter.format(batch.totalPurchaseCost),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (_selecting) {
                    return GestureDetector(
                      onLongPress: () => _toggleSelect(batch.id),
                      child: card,
                    );
                  }
                  return Dismissible(
                    key: ValueKey('batch-${batch.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.roseSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.rose, width: 1),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Icon(
                        HeroIcons.trash,
                        color: AppColors.rose,
                      ),
                    ),
                    confirmDismiss: (_) => _confirmDeleteBatch(batch),
                    child: card,
                  );
                }),
                if (batchesProvider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!batchesProvider.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        '— End of Batches —',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: context
              .watch<AuthProvider>()
              .capabilities
              .can(Capability.createBatch)
          ? FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: _openCreate,
              icon: const Icon(HeroIcons.plus, size: 18),
              label: Text(
                'New Batch',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }

  Widget _hero(ThemeData theme) {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: const Icon(
              HeroIcons.cube_transparent,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supply Pipeline & Logistics',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Track produce from farm procurement to market wholesale delivery.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: 1,
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
