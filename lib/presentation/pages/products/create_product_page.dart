import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/measurement_unit_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_dropdown.dart';

class CreateProductPage extends StatefulWidget {
  final ProductModel? product;

  const CreateProductPage({super.key, this.product});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  String _baseUnit = 'kg';
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameCtrl.text = product.name;
      _categoryCtrl.text = product.category ?? '';
      _baseUnit = product.baseUnit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildData(String businessId) => {
    'business_id': businessId,
    'name': _nameCtrl.text.trim(),
    'category': _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
    'base_unit': _baseUnit,
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    final ProductModel? saved;
    if (_isEditing) {
      saved = await provider.update(widget.product!.id, _buildData(businessId));
    } else {
      saved = await provider.create(_buildData(businessId));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Produce line updated successfully' : 'Produce line created successfully',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save produce line')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customUnits = context.watch<MeasurementUnitProvider>().units;
    final knownKeys = {
      ...purchaseUnits.map((u) => u.key),
      ...customUnits.map((u) => u.id),
    };
    // A pre-existing product may carry a free-text unit typed before this
    // dropdown existed — keep it selectable so editing doesn't blank it out.
    final isLegacyUnit = !knownKeys.contains(_baseUnit);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Produce Line' : 'Create Produce Line'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Produce name (e.g., Tomato)'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category (e.g., Vegetables)'),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                value: _baseUnit,
                labelText: 'Measurement unit',
                items: [
                  if (isLegacyUnit)
                    DropdownItem(value: _baseUnit, child: Text(_baseUnit)),
                  for (final u in purchaseUnits)
                    DropdownItem(value: u.key, child: Text(u.label)),
                  for (final u in customUnits)
                    DropdownItem(value: u.id, child: Text(u.name)),
                ],
                onChanged: (value) => setState(() => _baseUnit = value ?? 'kg'),
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
                      : Text(_isEditing ? 'Save Changes' : 'Save Produce Line'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
