import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'create_vehicle_page.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<VehicleProvider>().load(businessId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateVehiclePage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<VehicleProvider>().load(businessId);
  }

  Future<void> _openEdit(VehicleModel vehicle) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateVehiclePage(vehicle: vehicle)),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<VehicleProvider>().load(businessId);
  }

  Future<bool> _confirmDelete(VehicleModel vehicle) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<VehicleProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${vehicle.plateNumber}?',
      message: 'This transport vehicle will be permanently deleted from the active registry.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok != true) return false;
    final deleted = await provider.delete(vehicle.id);
    if (!context.mounted) return deleted;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Vehicle deleted' : (provider.error ?? 'Failed to delete vehicle'),
        ),
      ),
    );
    return deleted;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final allVehicles = vehicleProvider.vehicles;

    final query = _searchCtrl.text.trim().toLowerCase();
    final filteredVehicles = query.isEmpty
        ? allVehicles
        : allVehicles.where((v) {
            final plate = v.plateNumber.toLowerCase();
            final driver = (v.driverName ?? '').toLowerCase();
            final phone = (v.driverPhone ?? '').toLowerCase();
            final notes = (v.notes ?? '').toLowerCase();
            return plate.contains(query) ||
                driver.contains(query) ||
                phone.contains(query) ||
                notes.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Logistics & Fleet Vehicles',
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
          'Add Vehicle',
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
                    color: AppColors.skySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sky.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Icon(HeroIcons.truck, size: 24, color: AppColors.sky),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Registry & Transport Drivers',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage trucks, tractor-trolleys, drivers, and contact numbers for produce transit.',
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
              hintText: 'Search by plate number, driver name, or phone...',
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
          if (vehicleProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vehicleProvider.error != null)
            GreenCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                  const SizedBox(height: 10),
                  Text(vehicleProvider.error!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      final bId = context.read<AuthProvider>().businessId ?? '';
                      if (bId.isNotEmpty) vehicleProvider.load(bId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (filteredVehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                icon: HeroIcons.truck,
                title: query.isNotEmpty ? 'No matching vehicles found' : 'No transport vehicles added',
                subtitle: query.isNotEmpty
                    ? 'Try modifying your search term.'
                    : 'Add trucks and transport drivers to log logistics and transit routes.',
                actionLabel: 'Add Vehicle',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: filteredVehicles.map((vehicle) {
                return Dismissible(
                  key: ValueKey('vehicle-${vehicle.id}'),
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
                  confirmDismiss: (_) => _confirmDelete(vehicle),
                  child: GreenCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    onTap: () => _openEdit(vehicle),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.skySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.sky.withValues(alpha: 0.2), width: 1),
                          ),
                          child: const Icon(HeroIcons.truck, size: 22, color: AppColors.sky),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.plateNumber,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [vehicle.driverName, vehicle.driverPhone].where((e) => e != null && e.isNotEmpty).join(' • '),
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
