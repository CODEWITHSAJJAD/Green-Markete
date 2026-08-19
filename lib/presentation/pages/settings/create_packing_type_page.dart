import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/packing_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/packing_type_provider.dart';

class CreatePackingTypePage extends StatefulWidget {
  final PackingTypeModel? packingType;

  const CreatePackingTypePage({super.key, this.packingType});

  @override
  State<CreatePackingTypePage> createState() => _CreatePackingTypePageState();
}

class _CreatePackingTypePageState extends State<CreatePackingTypePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.packingType != null;

  @override
  void initState() {
    super.initState();
    final type = widget.packingType;
    if (type != null) {
      _nameCtrl.text = type.name;
      _kgCtrl.text = type.kgCapacity.toString();
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
    final provider = context.read<PackingTypeProvider>();
    final name = _nameCtrl.text.trim();
    final kg = double.parse(_kgCtrl.text.trim());
    final ok = _isEditing
        ? await provider.update(
            id: widget.packingType!.id,
            businessId: businessId,
            name: name,
            kgCapacity: kg,
          )
        : await provider.create(businessId: businessId, name: name, kgCapacity: kg);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Packing type updated' : 'Packing type added'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save packing type')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Packing Type' : 'Create Packing Type'),
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
                  labelText: 'Packing name',
                  hintText: 'e.g. Jute bag (50 kg)',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kgCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Capacity (kg)',
                  hintText: 'e.g. 50',
                ),
                validator: (value) {
                  final v = double.tryParse((value ?? '').trim());
                  if (v == null || v <= 0) return 'Enter a capacity greater than 0';
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
                      : Text(_isEditing ? 'Save Changes' : 'Save Packing Type'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
