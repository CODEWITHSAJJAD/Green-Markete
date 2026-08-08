import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import 'quick_sale_page.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key, this.onMenu});

  final VoidCallback? onMenu;

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<BatchListProvider>().load(businessId, status: 'selling');
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
    final batchesProvider = context.watch<BatchListProvider>();
    final sellingBatches = batchesProvider.batches;
    final isLoading = batchesProvider.isLoading;
    final error = batchesProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
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
                  theme.colorScheme.secondary.withValues(alpha: 0.08),
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
                Text('Revenue capture workflow', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Quick sale entry is tied to active selling batches so revenue, credit, and cash mode stay aligned with backend P&L.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openCreate,
                  icon: const Icon(Icons.point_of_sale_rounded),
                  label: const Text('Record New Sale'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Ready-to-sell batches', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
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
          else if (sellingBatches.isEmpty)
            const Text('No batches are currently in selling status.')
          else
            Column(
              children: sellingBatches
                  .map(
                    (batch) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
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
                          OutlinedButton(
                            onPressed: _openCreate,
                            child: const Text('Sell'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
