import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/measurement_unit_model.dart';
import '../../../data/models/packing_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/measurement_unit_provider.dart';
import '../../providers/packing_type_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'create_measurement_unit_page.dart';
import 'create_packing_type_page.dart';

class UnitsPackingPage extends StatefulWidget {
  const UnitsPackingPage({super.key});

  @override
  State<UnitsPackingPage> createState() => _UnitsPackingPageState();
}

class _UnitsPackingPageState extends State<UnitsPackingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isEmpty) return;
      context.read<MeasurementUnitProvider>().load(businessId);
      context.read<PackingTypeProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Units & Packing',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Measurement Units'),
            Tab(text: 'Packing Types'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_MeasurementUnitsTab(), _PackingTypesTab()],
      ),
    );
  }
}

class _MeasurementUnitsTab extends StatelessWidget {
  const _MeasurementUnitsTab();

  Future<void> _openEditor(BuildContext context, {MeasurementUnitModel? existing}) async {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateMeasurementUnitPage(unit: existing),
      ),
    );
    if (context.mounted) {
      context.read<MeasurementUnitProvider>().load(businessId);
    }
  }

  Future<void> _delete(BuildContext context, MeasurementUnitModel unit) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<MeasurementUnitProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${unit.name}?',
      message: 'Purchases already recorded with this unit keep their stored weight.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return;
    final deleted = await provider.delete(unit.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Unit deleted' : (provider.error ?? 'Failed to delete unit')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeasurementUnitProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-unit',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(context),
        icon: const Icon(HeroIcons.plus, size: 18),
        label: Text(
          'Add Unit',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Built-in units (kg, gram, mann/40kg, bags, crates) are always '
              'available in the Purchase Unit dropdown. Add your own below — '
              'e.g. a supplier-specific "peti" or crate size.',
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.units.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: HeroIcons.cube,
                title: 'No custom units yet',
                subtitle: 'Tap "Add Unit" to create one for a supplier-specific measurement.',
              ),
            )
          else
            ...provider.units.map(
              (u) => Dismissible(
                key: ValueKey('unit-${u.id}'),
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
                confirmDismiss: (_) async {
                  await _delete(context, u);
                  return false;
                },
                child: GreenCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  onTap: () => _openEditor(context, existing: u),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          u.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${u.kgPerUnit.toStringAsFixed(u.kgPerUnit % 1 == 0 ? 0 : 2)} kg',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        HeroIcons.pencil_square,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PackingTypesTab extends StatelessWidget {
  const _PackingTypesTab();

  Future<void> _openEditor(BuildContext context, {PackingTypeModel? existing}) async {
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePackingTypePage(packingType: existing),
      ),
    );
    if (context.mounted) {
      context.read<PackingTypeProvider>().load(businessId);
    }
  }

  Future<void> _delete(BuildContext context, PackingTypeModel type) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PackingTypeProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${type.name}?',
      message: 'Packing records already saved with this type keep their stored weight.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return;
    final deleted = await provider.delete(type.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Packing type deleted' : (provider.error ?? 'Failed to delete packing type')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackingTypeProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-packing-type',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(context),
        icon: const Icon(HeroIcons.plus, size: 18),
        label: Text(
          'Add Packing Type',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Built-in packing types (5/60/100kg bags, 15/20kg crates, and '
              'Custom packing for loose/leftover weight) are always available '
              'when packing a batch. Add your own bag/crate sizes below.',
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.types.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: HeroIcons.archive_box,
                title: 'No custom packing types yet',
                subtitle: 'Tap "Add Packing Type" to create one for a bag or crate size you use.',
              ),
            )
          else
            ...provider.types.map(
              (t) => Dismissible(
                key: ValueKey('packing-type-${t.id}'),
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
                confirmDismiss: (_) async {
                  await _delete(context, t);
                  return false;
                },
                child: GreenCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  onTap: () => _openEditor(context, existing: t),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${t.kgCapacity.toStringAsFixed(t.kgCapacity % 1 == 0 ? 0 : 2)} kg',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        HeroIcons.pencil_square,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
