import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/product_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<AuthProvider>().businessId ?? '';
      context.read<ProductProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final provider = context.watch<ProductProvider>();

    final query = _searchCtrl.text.trim().toLowerCase();
    final allProducts = provider.products;
    final filteredProducts = query.isEmpty
        ? allProducts
        : allProducts.where((p) {
            final name = p.name.toLowerCase();
            final cat = (p.category ?? '').toLowerCase();
            final unit = p.baseUnit.toLowerCase();
            return name.contains(query) || cat.contains(query) || unit.contains(query);
          }).toList();

    Widget productsSection;
    if (provider.isLoading) {
      productsSection = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (provider.error != null) {
      productsSection = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(provider.error!.toString()),
      );
    } else if (filteredProducts.isEmpty) {
      productsSection = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: EmptyState(
          icon: HeroIcons.sparkles,
          title: query.isNotEmpty ? 'No matching produce items' : 'No produce varieties added',
          subtitle: query.isNotEmpty
              ? 'Try modifying your search term.'
              : 'Add vegetables, fruits, and units to build your wholesale produce catalog.',
          actionLabel: 'Add Variety',
          onAction: () => _showCreateDialog(context, businessId),
        ),
      );
    } else {
      productsSection = Column(
        children: filteredProducts
            .map(
              (product) => Dismissible(
                key: ValueKey('product-${product.id}'),
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
                confirmDismiss: (_) => _confirmDelete(product),
                child: GestureDetector(
                  onTap: () => _showEditDialog(context, businessId, product),
                  child: GreenCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25), width: 1),
                          ),
                          child: const Icon(HeroIcons.sparkles, color: AppColors.emerald, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.category ?? 'General Produce',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider, width: 0.8),
                          ),
                          child: Text(
                            product.baseUnit.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          HeroIcons.pencil_square,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Produce Varieties & Catalog',
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
        onPressed: () => _showCreateDialog(context, businessId),
        icon: const Icon(HeroIcons.plus, size: 18),
        label: Text(
          'Add Variety',
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
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(HeroIcons.tag, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produce Lines & Units',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Standardize vegetable & fruit names, categories, and measurement units.',
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
              hintText: 'Search produce by name, category, or unit...',
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
          productsSection,
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(ProductModel product) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${product.name}?',
      message: 'Are you sure you want to remove this product variety from your catalog?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return false;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    final prov = context.read<ProductProvider>();
    final deleted = await prov.delete(product.id);
    if (deleted && mounted) {
      DataRefreshNotifier.instance.refresh(businessId);
    }
    return deleted;
  }

  void _showCreateDialog(BuildContext context, String businessId) {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'kg');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Produce Line',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Produce Name (e.g., Tomato)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(labelText: 'Category (e.g., Vegetables)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Measurement Unit (e.g., kg, crate, bag)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await context.read<ProductProvider>().create({
                'business_id': businessId,
                'name': nameCtrl.text.trim(),
                if (catCtrl.text.trim().isNotEmpty) 'category': catCtrl.text.trim(),
                'base_unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String businessId, ProductModel product) {
    final nameCtrl = TextEditingController(text: product.name);
    final catCtrl = TextEditingController(text: product.category ?? '');
    final unitCtrl = TextEditingController(text: product.baseUnit);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit ${product.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Produce Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Measurement Unit'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await context.read<ProductProvider>().update(product.id, {
                'business_id': businessId,
                'name': nameCtrl.text.trim(),
                if (catCtrl.text.trim().isNotEmpty) 'category': catCtrl.text.trim(),
                'base_unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
