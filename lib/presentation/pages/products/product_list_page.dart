import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/green_card.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = context.read<AuthProvider>().businessId ?? '';
      context.read<ProductProvider>().load(businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final provider = context.watch<ProductProvider>();

    Widget productsSection;
    if (provider.isLoading) {
      productsSection = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (provider.error != null) {
      productsSection = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(provider.error!.toString()),
      );
    } else if (provider.products.isEmpty) {
      productsSection = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(MingCuteIcons.mgc_package_line, size: 52, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No products yet', style: theme.textTheme.titleLarge),
          ],
        ),
      );
    } else {
      productsSection = Column(
        children: provider.products
            .map(
              (product) => Dismissible(
                key: ValueKey('product-${product.id}'),
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
                confirmDismiss: (_) => _confirmDelete(product),
                child: GestureDetector(
                  onTap: () => _showEditDialog(context, businessId, product),
                  child: GreenCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(MingCuteIcons.mgc_leaf_2_line, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(product.category ?? 'Uncategorized', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(product.baseUnit, style: theme.textTheme.labelMedium),
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(MingCuteIcons.mgc_add_line),
            onPressed: () => _showCreateDialog(context, businessId),
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
                  theme.colorScheme.primary.withValues(alpha: 0.09),
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
                Text('Product catalog', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Define categories, units, and produce lines used across purchasing, packing, and sales.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          productsSection,
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, String businessId) async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'kg');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Product name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 12),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Base unit')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final productProvider = context.read<ProductProvider>();
              await productProvider.create({
                'business_id': businessId,
                'name': nameCtrl.text.trim(),
                'category': catCtrl.text.trim(),
                'base_unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
              });
              productProvider.load(businessId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, String businessId, ProductModel product) async {
    final nameCtrl = TextEditingController(text: product.name);
    final catCtrl = TextEditingController(text: product.category ?? '');
    final unitCtrl = TextEditingController(text: product.baseUnit);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Product'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 12),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Base unit')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final productProvider = context.read<ProductProvider>();
              await productProvider.update(product.id, {
                'name': nameCtrl.text.trim(),
                'category': catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
                'base_unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
              });
              productProvider.load(businessId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(ProductModel product) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProductProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${product.name}?',
      message: 'This product will be permanently deleted. Batches that already reference it keep their records.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return false;
    final deleted = await provider.delete(product.id);
    if (!context.mounted) return deleted;
    messenger.showSnackBar(
      SnackBar(content: Text(deleted ? 'Product deleted' : 'Failed to delete product')),
    );
    return deleted;
  }
}
