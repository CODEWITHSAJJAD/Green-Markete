import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';

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
        'shop_name': _shopCtrl.text.trim().isEmpty
            ? null
            : _shopCtrl.text.trim(),
      };
      final customer = _isEditing
          ? await provider.update(widget.customer!.id, data)
          : await provider.create(data);
      if (!mounted) return;
      if (customer != null) {
        DataRefreshNotifier.instance.refresh(businessId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Customer updated successfully'
                  : 'Customer created successfully',
            ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Customer Profile' : 'Register New Customer',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
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
                  labelText: 'Full Name (required)',
                  hintText: 'e.g. Haji Rashid Ahmed',
                  prefixIcon: Icon(HeroIcons.user, size: 20),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                    ? 'Please enter Customer name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '03001234567',
                  prefixIcon: Icon(HeroIcons.phone, size: 20),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.phone(value);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _shopCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shop / Business Name',
                  hintText: 'e.g. Rashid Sabzi Stall #42',
                  prefixIcon: Icon(
                    HeroIcons.building_storefront,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City / Wholesale Mandi',
                  hintText: 'e.g. Badami Bagh, Lahore',
                  prefixIcon: Icon(HeroIcons.map_pin, size: 20),
                ),
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Customer',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
