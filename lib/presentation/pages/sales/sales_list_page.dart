import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import '../../widgets/section_header.dart';
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
          icon: const Icon(MingCuteIcons.mgc_menu_line),
          onPressed: widget.onMenu,
        ),
        actions: [
          IconButton(
            icon: const Icon(MingCuteIcons.mgc_add_line),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _hero(theme),
          const SizedBox(height: 20),
          SectionHeader(title: 'Ready-to-sell batches'),
          const SizedBox(height: 4),
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
          else if (sellingBatches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: EmptyState(
                icon: MingCuteIcons.mgc_bill_line,
                title: 'No batches on sale yet',
                subtitle: 'Move a batch to \'selling\' status to start recording revenue against it.',
                actionLabel: 'Record Sale',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: sellingBatches.map((batch) {
                return GreenCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  onTap: _openCreate,
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
                    title: Text(batch.productName ?? batch.batchCode),
                    subtitle: Text(batch.batchCode),
                    trailing: FilledButton(
                      onPressed: _openCreate,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Sell'),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
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
            AppColors.secondary.withValues(alpha: 0.10),
            AppColors.amberSurface.withValues(alpha: 0.6),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(MingCuteIcons.mgc_bill_line, size: 26, color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue capture', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Sales are tied to active selling batches so revenue and credit stay aligned with P&L.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _openCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(0, 50),
            ),
            icon: const Icon(MingCuteIcons.mgc_add_line, size: 18),
            label: const Text('Record New Sale'),
          ),
        ],
      ),
    );
  }
}
