import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CreateVehiclePage extends StatefulWidget {
  final VehicleModel? vehicle;

  const CreateVehiclePage({super.key, this.vehicle});

  @override
  State<CreateVehiclePage> createState() => _CreateVehiclePageState();
}

class _CreateVehiclePageState extends State<CreateVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _capacityValueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _capacityUnit = 'bag';
  bool _saving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _plateCtrl.text = vehicle.plateNumber;
      _driverNameCtrl.text = vehicle.driverName ?? '';
      _driverPhoneCtrl.text = vehicle.driverPhone ?? '';
      _capacityValueCtrl.text = vehicle.capacityValue == null
          ? ''
          : _formatNumber(vehicle.capacityValue!);
      _capacityUnit = vehicle.capacityUnit ?? 'bag';
      _notesCtrl.text = vehicle.notes ?? '';
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _capacityValueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  Map<String, dynamic> _buildData(String businessId) => {
    'business_id': businessId,
    'plate_number': _plateCtrl.text.trim(),
    'driver_name': _driverNameCtrl.text.trim().isEmpty
        ? null
        : _driverNameCtrl.text.trim(),
    'driver_phone': _driverPhoneCtrl.text.trim().isEmpty
        ? null
        : _driverPhoneCtrl.text.trim(),
    'capacity_value': double.tryParse(_capacityValueCtrl.text.trim()),
    'capacity_unit': _capacityUnit,
    'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final provider = context.read<VehicleProvider>();
    final VehicleModel? saved;
    if (_isEditing) {
      saved = await provider.update(widget.vehicle!.id, _buildData(businessId));
    } else {
      saved = await provider.create(_buildData(businessId));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Vehicle updated successfully'
                : 'Vehicle created successfully',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save vehicle')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Create Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'Plate number'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Capacity value'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField2<String>(
                isExpanded: true,
                valueListenable: ValueNotifier(_capacityUnit),
                decoration: const InputDecoration(labelText: 'Capacity unit'),
                items: const [
                  DropdownItem(value: 'bag', child: Text('Bags')),
                  DropdownItem(value: 'kg', child: Text('Kilograms')),
                  DropdownItem(value: 'crate', child: Text('Crates')),
                  DropdownItem(value: 'unit', child: Text('Units')),
                ],
                onChanged: (value) =>
                    setState(() => _capacityUnit = value ?? 'bag'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Save Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
