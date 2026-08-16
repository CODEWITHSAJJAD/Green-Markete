import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
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
      message: 'This market will be permanently deleted. Batches referencing it will retain their history.',
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mandi & Market Terminals',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _openCreate,
        icon: const Icon(HeroIcons.plus, size: 18),
        label: Text(
          'Add Mandi / Market',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
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
                    color: AppColors.indigoSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.indigo.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Icon(HeroIcons.building_storefront, size: 24, color: AppColors.indigo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wholesale Market Directory',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage wholesale Mandis, trade yards, and delivery destination terminals.',
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
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search markets by name, city, or address...',
              prefixIcon: const Icon(HeroIcons.magnifying_glass, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(HeroIcons.x_circle, size: 18),
                      onPressed: () => setState(() => _searchCtrl.clear()),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          if (marketProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (marketProvider.error != null)
            GreenCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                  const SizedBox(height: 10),
                  Text(marketProvider.error!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      final bId = context.read<AuthProvider>().businessId ?? '';
                      if (bId.isNotEmpty) marketProvider.load(bId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (filteredMarkets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                icon: HeroIcons.building_storefront,
                title: query.isNotEmpty ? 'No matching markets found' : 'No wholesale markets added',
                subtitle: query.isNotEmpty
                    ? 'Try a different search keyword.'
                    : 'Add wholesale grain and vegetable Mandis to assign destination endpoints.',
                actionLabel: 'Add Market',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: filteredMarkets.map((market) {
                return Dismissible(
                  key: ValueKey('market-${market.id}'),
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
                    child: const Icon(HeroIcons.trash, color: AppColors.rose),
                  ),
                  confirmDismiss: (_) => _confirmDelete(market),
                  child: GreenCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    onTap: () => _openEdit(market),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider, width: 1),
                          ),
                          child: const Icon(HeroIcons.building_storefront, size: 22, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                market.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [market.city, market.address].where((e) => e != null && e.isNotEmpty).join(' • '),
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(HeroIcons.pencil_square, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
