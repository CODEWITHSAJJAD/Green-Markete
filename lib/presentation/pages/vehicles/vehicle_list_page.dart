import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/green_card.dart';
import 'create_vehicle_page.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) context.read<VehicleProvider>().load(businessId);
    });
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateVehiclePage()),
    );
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().businessId ?? '';
    if (businessId.isNotEmpty) context.read<VehicleProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final vehicleProvider = context.watch<VehicleProvider>();
    final vehicles = vehicleProvider.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(MingCuteIcons.mgc_truck_line),
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
                Text('Fleet & transport', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Register the vehicles that carry your batches and split loads to track shared transport.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (vehicleProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vehicleProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(vehicleProvider.error.toString()),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<VehicleProvider>().load(businessId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: EmptyState(
                icon: MingCuteIcons.mgc_truck_line,
                title: 'No vehicles found',
                subtitle: 'Register your fleet to track shared transport loads per batch.',
                actionLabel: 'New Vehicle',
                onAction: _openCreate,
              ),
            )
          else
            Column(
              children: vehicles
                  .map(
                    (vehicle) => GreenCard(
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
                            child: Icon(MingCuteIcons.mgc_truck_line, color: theme.colorScheme.secondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vehicle.plateNumber, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    vehicle.driverName,
                                    if (vehicle.capacityValue != null)
                                      '${_formatCapacity(vehicle.capacityValue!)}${vehicle.capacityUnit ?? ''}',
                                  ]
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
        heroTag: null,
        onPressed: _openCreate,
        icon: const Icon(MingCuteIcons.mgc_truck_line),
        label: const Text('New Vehicle'),
      ),
    );
  }

  String _formatCapacity(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}
