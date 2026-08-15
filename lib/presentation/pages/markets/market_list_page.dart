import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/market_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'create_market_page.dart';

class MarketListPage extends StatefulWidget {
  const MarketListPage({super.key});

  @override
  State<MarketListPage> createState() => _MarketListPageState();
}

class _MarketListPageState extends State<MarketListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<MarketProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateMarketPage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<MarketProvider>().load(businessId);
  }

  Future<void> _openEdit(MarketModel market) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateMarketPage(market: market)),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<MarketProvider>().load(businessId);
  }

  Future<bool> _confirmDelete(MarketModel market) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<MarketProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${market.name}?',
      message: 'This market will be permanently deleted. Batches that already reference it keep their records.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return false;
    final deleted = await provider.delete(market.id);
    if (!context.mounted) return deleted;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Market deleted' : (provider.error ?? 'Failed to delete market'),
        ),
      ),
    );
    return deleted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final marketProvider = context.watch<MarketProvider>();
    final allMarkets = marketProvider.markets;

    final query = _searchCtrl.text.trim().toLowerCase();
    final filteredMarkets = query.isEmpty
        ? allMarkets
        : allMarkets.where((m) {
            final name = m.name.toLowerCase();
            final city = m.city.toLowerCase();
            final address = (m.address ?? '').toLowerCase();
            return name.contains(query) || city.contains(query) || address.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _openCreate,
        icon: const Icon(MingCuteIcons.mgc_store_2_line),
        label: const Text('New Market'),
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
                  theme.colorScheme.secondary.withValues(alpha: 0.10),
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
                Text('City & market network', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Organize source and destination markets, stalls, and routes for every batch.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search markets by name or city',
                    prefixIcon: const Icon(MingCuteIcons.mgc_search_2_line),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(MingCuteIcons.mgc_close_line),
                            onPressed: () => setState(() => _searchCtrl.clear()),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (marketProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (marketProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(marketProvider.error.toString()),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<MarketProvider>().load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (filteredMarkets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: EmptyState(
                icon: MingCuteIcons.mgc_store_2_line,
                title: query.isNotEmpty ? 'No matching markets' : 'No markets found',
                subtitle: 'Add source and destination markets to organise batch routes.',
                actionLabel: 'New Market',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: filteredMarkets
                  .map(
                    (market) => Dismissible(
                      key: ValueKey('market-${market.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Icon(MingCuteIcons.mgc_delete_2_line, color: theme.colorScheme.error),
                      ),
                      confirmDismiss: (_) => _confirmDelete(market),
                      child: GestureDetector(
                        onTap: () => _openEdit(market),
                        child: GreenCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(MingCuteIcons.mgc_store_2_line, color: theme.colorScheme.secondary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(market.name, style: theme.textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      [market.city, market.stallNumber, market.marketType]
                                          .where((item) => item != null && item.isNotEmpty)
                                          .join('  •  '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                MingCuteIcons.mgc_edit_2_line,
                                size: 20,
                                color: theme.colorScheme.outline,
                              ),
                            ],
                          ),
                        ),
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
