import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/market_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CreateMarketPage extends StatefulWidget {
  final MarketModel? market;

  const CreateMarketPage({super.key, this.market});

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

  bool get _isEditing => widget.market != null;

  @override
  void initState() {
    super.initState();
    final market = widget.market;
    if (market != null) {
      _nameCtrl.text = market.name;
      _cityCtrl.text = market.city;
      _addressCtrl.text = market.address ?? '';
      _stallCtrl.text = market.stallNumber ?? '';
      _marketType = market.marketType ?? 'wholesale';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _stallCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildData(String businessId) => {
    'business_id': businessId,
    'name': _nameCtrl.text.trim(),
    'city': _cityCtrl.text.trim(),
    'address': _addressCtrl.text.trim().isEmpty
        ? null
        : _addressCtrl.text.trim(),
    'stall_number': _stallCtrl.text.trim().isEmpty
        ? null
        : _stallCtrl.text.trim(),
    'market_type': _marketType,
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    setState(() => _saving = true);
    final provider = context.read<MarketProvider>();
    final MarketModel? saved;
    if (_isEditing) {
      saved = await provider.update(widget.market!.id, _buildData(businessId));
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
                ? 'Market updated successfully'
                : 'Market created successfully',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save market')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Market' : 'Create Market')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Market name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
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
              DropdownButtonFormField2<String>(
                isExpanded: true,
                valueListenable: ValueNotifier(_marketType),
                decoration: const InputDecoration(labelText: 'Market type'),
                items: const [
                  DropdownItem(value: 'wholesale', child: Text('Wholesale')),
                  DropdownItem(value: 'retail', child: Text('Retail')),
                  DropdownItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (value) =>
                    setState(() => _marketType = value ?? 'wholesale'),
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
                    : Text(_isEditing ? 'Save Changes' : 'Save Market'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
