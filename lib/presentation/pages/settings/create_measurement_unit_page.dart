import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/measurement_unit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/measurement_unit_provider.dart';

class CreateMeasurementUnitPage extends StatefulWidget {
  final MeasurementUnitModel? unit;

  const CreateMeasurementUnitPage({super.key, this.unit});

  @override
  State<CreateMeasurementUnitPage> createState() => _CreateMeasurementUnitPageState();
}

class _CreateMeasurementUnitPageState extends State<CreateMeasurementUnitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit;
    if (unit != null) {
      _nameCtrl.text = unit.name;
      _kgCtrl.text = unit.kgPerUnit.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final provider = context.read<MeasurementUnitProvider>();
    final name = _nameCtrl.text.trim();
    final kg = double.parse(_kgCtrl.text.trim());
    final ok = _isEditing
        ? await provider.update(
            id: widget.unit!.id,
            businessId: businessId,
            name: name,
            kgPerUnit: kg,
          )
        : await provider.create(businessId: businessId, name: name, kgPerUnit: kg);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Measurement unit updated' : 'Measurement unit added'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save unit')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Measurement Unit' : 'Create Measurement Unit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit name',
                  hintText: 'e.g. Peti',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kgCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight per unit (kg)',
                  hintText: 'e.g. 25',
                ),
                validator: (value) {
                  final v = double.tryParse((value ?? '').trim());
                  if (v == null || v <= 0) return 'Enter a weight greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                      : Text(_isEditing ? 'Save Changes' : 'Save Unit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
