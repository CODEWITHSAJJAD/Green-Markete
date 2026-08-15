import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/app_dropdown.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CreatePartnerPage extends StatefulWidget {
  const CreatePartnerPage({super.key});

  @override
  State<CreatePartnerPage> createState() => _CreatePartnerPageState();
}

class _CreatePartnerPageState extends State<CreatePartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _role = 'partner';
  String _accessLevel = 'viewer';
  bool _manageOtherSide = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final partner = await context.read<PartnerProvider>().create({
      'full_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'role': _role,
      'access_level': _accessLevel,
      'manage_other_side': _manageOtherSide,
      'business_id': businessId,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (partner != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner created successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<PartnerProvider>().error ?? 'Failed to create partner',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Partner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
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
              AppDropdown<String>(
                value: _role,
                labelText: 'Business role',
                items: const [
                  DropdownItem(value: 'purchaser', child: Text('Purchaser')),
                  DropdownItem(value: 'seller', child: Text('Seller')),
                  DropdownItem(value: 'both', child: Text('Both')),
                  DropdownItem(value: 'accountant', child: Text('Accountant')),
                  DropdownItem(value: 'partner', child: Text('Partner')),
                ],
                onChanged: (value) =>
                    setState(() => _role = value ?? 'partner'),
              ),
              const SizedBox(height: 16),
              AppDropdown<String>(
                value: _accessLevel,
                labelText: 'Access level',
                hintText:
                    'Editor can change batch status; Viewer writes their own side only',
                items: const [
                  DropdownItem(value: 'viewer', child: Text('Viewer')),
                  DropdownItem(value: 'editor', child: Text('Editor')),
                ],
                onChanged: (value) =>
                    setState(() => _accessLevel = value ?? 'viewer'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow editing the other side'),
                subtitle: const Text(
                  'Grant write access on both sides '
                  '(e.g. a purchaser can also manage sales).',
                ),
                value: _manageOtherSide,
                onChanged: (value) =>
                    setState(() => _manageOtherSide = value),
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
                    : const Text('Save Partner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
