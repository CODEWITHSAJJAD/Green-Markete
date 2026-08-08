import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import 'create_market_page.dart';

class MarketListPage extends StatefulWidget {
  const MarketListPage({super.key});

  @override
  State<MarketListPage> createState() => _MarketListPageState();
}

class _MarketListPageState extends State<MarketListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<MarketProvider>().load(businessId);
    });
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateMarketPage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<MarketProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final marketProvider = context.watch<MarketProvider>();
    final markets = marketProvider.markets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
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
          else if (markets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.storefront_outlined, size: 52, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No markets found', style: theme.textTheme.titleLarge),
                ],
              ),
            )
          else
            Column(
              children: markets
                  .map(
                    (market) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.store_mall_directory_rounded, color: theme.colorScheme.secondary),
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
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('New Market'),
      ),
    );
  }
}
