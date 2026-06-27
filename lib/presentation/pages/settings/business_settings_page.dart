import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/theme.dart';

class BusinessSettingsPage extends ConsumerStatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  ConsumerState<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends ConsumerState<BusinessSettingsPage> {
  final _nameController = TextEditingController(text: 'Green Market Trading');
  final _typeController = TextEditingController(text: 'multi_partner');
  final _cityController = TextEditingController(text: 'Lahore');
  final _addressController = TextEditingController(text: 'Main Market, Anarkali');
  final _phoneController = TextEditingController(text: '03001234567');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Business Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(labelText: 'Business Type'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        Future.delayed(const Duration(seconds: 1), () {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings saved')),
                          );
                        });
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
