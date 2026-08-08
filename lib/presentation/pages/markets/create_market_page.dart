import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';

class CreateMarketPage extends StatefulWidget {
  const CreateMarketPage({super.key});

  @override
  State<CreateMarketPage> createState() => _CreateMarketPageState();
}

class _CreateMarketPageState extends State<CreateMarketPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _stallCtrl = TextEditingController();
  String _marketType = 'wholesale';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _stallCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final market = await context.read<MarketProvider>().create({
      'business_id': businessId,
      'name': _nameCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'stall_number': _stallCtrl.text.trim(),
      'market_type': _marketType,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (market != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market created successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<MarketProvider>().error ?? 'Failed to create market')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Market')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Market name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stallCtrl,
                decoration: const InputDecoration(labelText: 'Stall number'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _marketType,
                decoration: const InputDecoration(labelText: 'Market type'),
                items: const [
                  DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                  DropdownMenuItem(value: 'retail', child: Text('Retail')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (value) => setState(() => _marketType = value ?? 'wholesale'),
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
                    : const Text('Save Market'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
