import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../../data/repositories/partner_repository.dart';

class CreatePartnerPage extends ConsumerStatefulWidget {
  const CreatePartnerPage({super.key});

  @override
  ConsumerState<CreatePartnerPage> createState() => _CreatePartnerPageState();
}

class _CreatePartnerPageState extends ConsumerState<CreatePartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _cityController = TextEditingController();
  String _role = 'partner';
  bool _sendInvitation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authProvider);
    final businessId = authState.user?.id ?? '';
    final repo = ref.read(partnerRepositoryProvider);
    await repo.create({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'city': _cityController.text.trim(),
      'role': _role,
      'business_id': businessId,
    });
    ref.invalidate(partnerListProvider(businessId));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Partner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone *'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cnicController,
                decoration: const InputDecoration(labelText: 'CNIC (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'purchaser', child: Text('Purchaser')),
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                  DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                  DropdownMenuItem(value: 'partner', child: Text('Partner')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Send invitation later'),
                value: _sendInvitation,
                onChanged: (v) => setState(() => _sendInvitation = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Partner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
