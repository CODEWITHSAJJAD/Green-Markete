import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batchesProvider = context.watch<BatchListProvider>();
    final batches = batchesProvider.batches;
    final isLoading = batchesProvider.isLoading;
    final error = batchesProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batches'),
        leading: IconButton(
          icon: const Icon(MingCute.menu_line),
          onPressed: widget.onMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(MingCute.add_line),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: ListView(
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
                  Icon(MingCute.wifi_off_line, size: 44, color: theme.colorScheme.error.withValues(alpha: 0.5)),
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
                icon: MingCute.shopping_bag_2_line,
                title: 'No batches yet',
                subtitle: 'Create your first batch to start tracking produce from purchase to sale.',
                actionLabel: 'New Batch',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: batches.map((batch) {
                return GreenCard(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: batch.id)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(MingCute.shopping_bag_2_line, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
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
              }).toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(MingCute.add_line),
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
            child: const Icon(MingCute.shopping_bag_2_line, size: 26, color: AppColors.primary),
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
