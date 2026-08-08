import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/error_snackbar.dart';

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _thresholdCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _thresholdCtrl = TextEditingController();
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context.read<BusinessProvider>().load(businessId);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(BusinessProvider provider) {
    final business = provider.business;
    if (business == null) return;
    if (_nameCtrl.text != business.name) {
      _nameCtrl.text = business.name;
    }
    final threshold = business.creditAlertThreshold?.toStringAsFixed(0) ?? '';
    if (_thresholdCtrl.text != threshold) {
      _thresholdCtrl.text = threshold;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Business name is required');
      return;
    }
    setState(() => _saving = true);
    final threshold = double.tryParse(_thresholdCtrl.text.trim());
    if (threshold != null && threshold < 0) {
      setState(() => _saving = false);
      showErrorSnackbar(context, 'Threshold must be a positive number');
      return;
    }
    final ok = await context.read<BusinessProvider>().updateSettings(
      name: _nameCtrl.text.trim(),
      creditAlertThreshold: threshold,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showSuccessSnackbar(context, 'Business settings updated');
    } else {
      showErrorSnackbar(
        context,
        context.read<BusinessProvider>().error ?? 'Failed to update settings',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    _syncControllers(provider);
    final business = provider.business;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.isLoading && business == null) ...[
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (business == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    provider.error ?? 'Business details not available.',
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Business name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _thresholdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credit alert threshold',
                  helperText: 'Notify when a customer balance reaches this amount.',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
