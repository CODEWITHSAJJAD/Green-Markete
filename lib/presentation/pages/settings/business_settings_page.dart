import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
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
  late String _currencyCode;
  bool _saving = false;

  static const List<String> _currencyOptions = [
    'PKR',
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AED',
    'SAR',
    'CNY',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _thresholdCtrl = TextEditingController();
    _currencyCode = 'PKR';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId;
      if (businessId != null && businessId.isNotEmpty) {
        context.read<BusinessProvider>().load(businessId);
      }
    });
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
    if (_currencyCode != business.currencyCode) {
      _currencyCode = business.currencyCode;
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
      currencyCode: _currencyCode,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showSuccessSnackbar(context, 'Business settings updated');
    } else {
      showErrorSnackbar(
        context,
        context.read<BusinessProvider>().error ??
            'Failed to update settings. The backend may need a currency_code column.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    _syncControllers(provider);
    final business = provider.business;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuBusinessInfo)),
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
                onChanged: (v) {
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) return;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _currencyOptions.contains(_currencyCode)
                    ? _currencyCode
                    : _currencyOptions.first,
                decoration: InputDecoration(labelText: l10n.settingsCurrency),
                items: [
                  for (final c in _currencyOptions)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _currencyCode = v);
                },
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