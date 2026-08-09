import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';

class CreateCustomerPage extends StatefulWidget {
  final CustomerModel? customer;

  const CreateCustomerPage({super.key, this.customer});

  @override
  State<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

class _CreateCustomerPageState extends State<CreateCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer != null) {
      _nameCtrl.text = customer.fullName;
      _phoneCtrl.text = customer.phone ?? '';
      _cityCtrl.text = customer.city ?? '';
      _shopCtrl.text = customer.shopName ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _shopCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    try {
      final provider = context.read<CustomerProvider>();
      final data = {
        'business_id': businessId,
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'shop_name': _shopCtrl.text.trim().isEmpty ? null : _shopCtrl.text.trim(),
      };
      final customer = _isEditing
          ? await provider.update(widget.customer!.id, data)
          : await provider.create(data);
      if (!mounted) return;
      if (customer != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Customer updated successfully' : 'Customer created successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final err = context.read<CustomerProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err?.toString() ?? 'Failed to save customer')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Customer' : 'Create Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return Validators.phone(v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shopCtrl,
                decoration: const InputDecoration(labelText: 'Shop / stall'),
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
                    : Text(_isEditing ? 'Save Changes' : 'Save Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
