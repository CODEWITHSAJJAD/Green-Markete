import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
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
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  void _toggleSelect(String id) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchesProvider = context.watch<BatchListProvider>();
    final batches = batchesProvider.batches;
    final isLoading = batchesProvider.isLoading;
    final error = batchesProvider.error;

    return Scaffold(
      appBar: _selecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(MingCuteIcons.mgc_close_line),
                onPressed: _exitSelect,
                tooltip: 'Cancel selection',
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  tooltip: 'Mark as closed',
                  onPressed: _selectedIds.isEmpty ? null : _bulkClose,
                  icon: const Icon(MingCuteIcons.mgc_archive_line),
                ),
              ],
            )
          : AppBar(
              title: Text(AppLocalizations.of(context)!.batchesScreenTitle),
              leading: IconButton(
                icon: const Icon(MingCuteIcons.mgc_menu_line),
                onPressed: widget.onMenu,
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
              context.read<BatchListProvider>().loadMore();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _hero(theme),
              const SizedBox(height: 20),
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
                      Icon(MingCuteIcons.mgc_wifi_off_line, size: 44, color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(error, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _load,
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (batches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: EmptyState(
                    icon: MingCuteIcons.mgc_shopping_bag_2_line,
                    title: 'No batches yet',
                    subtitle: 'Create your first batch to start tracking produce from purchase to sale.',
                    actionLabel: 'New Batch',
                    onAction: _openCreate,
                  ),
                )
              else ...[
                ...batches.map((batch) {
                  final isSelected = _selectedIds.contains(batch.id);
                  final card = GreenCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.06)
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
                                      ? MingCuteIcons.mgc_check_fill
                                      : MingCuteIcons.mgc_check_line,
                                  color: isSelected
                                      ? AppColors.primary
                                      : theme.colorScheme.outline,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(MingCuteIcons.mgc_shopping_bag_2_line, color: AppColors.primary),
                              ),
                            SizedBox(width: _selecting ? 0 : 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(batch.productName ?? batch.batchCode, style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(batch.batchCode, style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            StatusPill(status: batch.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _meta(theme, 'Quantity', '${batch.totalQuantity.toStringAsFixed(0)} ${batch.quantityUnit}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _meta(theme, 'Purchase cost', CurrencyFormatter.format(batch.totalPurchaseCost)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  if (!_selecting) return card;
                  return GestureDetector(
                    onLongPress: () => _toggleSelect(batch.id),
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
                        '— end of list —',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _openCreate,
        icon: const Icon(MingCuteIcons.mgc_add_line),
        label: const Text('New Batch'),
      ),
    );
  }

  Widget _hero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primarySurface.withValues(alpha: 0.6),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(MingCuteIcons.mgc_shopping_bag_2_line, size: 26, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch lifecycle', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Follow produce from purchase to selling, with transport, packing, and P&L in one timeline.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(ThemeData theme, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
