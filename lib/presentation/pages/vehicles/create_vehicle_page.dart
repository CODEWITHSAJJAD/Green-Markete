import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';

class CreateVehiclePage extends StatefulWidget {
  const CreateVehiclePage({super.key});

  @override
  State<CreateVehiclePage> createState() => _CreateVehiclePageState();
}

class _CreateVehiclePageState extends State<CreateVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _capacityValueCtrl = TextEditingController();
  String _capacityUnit = 'bag';
  bool _saving = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _capacityValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final vehicle = await context.read<VehicleProvider>().create({
      'business_id': businessId,
      'plate_number': _plateCtrl.text.trim(),
      'driver_name': _driverNameCtrl.text.trim().isEmpty ? null : _driverNameCtrl.text.trim(),
      'driver_phone': _driverPhoneCtrl.text.trim().isEmpty ? null : _driverPhoneCtrl.text.trim(),
      'capacity_value': double.tryParse(_capacityValueCtrl.text.trim()),
      'capacity_unit': _capacityUnit,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (vehicle != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle created successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<VehicleProvider>().error ?? 'Failed to create vehicle')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'Plate number'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverNameCtrl,
                decoration: const InputDecoration(labelText: 'Driver name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _driverPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Driver phone'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityValueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Capacity value'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _capacityUnit,
                decoration: const InputDecoration(labelText: 'Capacity unit'),
                items: const [
                  DropdownMenuItem(value: 'bag', child: Text('Bags')),
                  DropdownMenuItem(value: 'kg', child: Text('Kilograms')),
                  DropdownMenuItem(value: 'crate', child: Text('Crates')),
                  DropdownMenuItem(value: 'unit', child: Text('Units')),
                ],
                onChanged: (value) => setState(() => _capacityUnit = value ?? 'bag'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
