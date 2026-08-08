import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch lifecycle control', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Follow produce from purchase to selling, with transport, packing, and P&L in one timeline.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(error),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (batches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 52, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No batches yet', style: theme.textTheme.titleLarge),
                ],
              ),
            )
          else
            Column(
              children: batches
                  .map(
                    (batch) => GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: batch.id)),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.inventory_2_rounded, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(batch.productName ?? batch.batchCode, style: theme.textTheme.titleMedium),
                                      const SizedBox(height: 4),
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
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('New Batch'),
      ),
    );
  }

  Widget _meta(ThemeData theme, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
