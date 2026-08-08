import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/green_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  String _businessType = 'multi_partner';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final business = await context.read<BusinessProvider>().create(
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          businessType: _businessType,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (business != null) {
      context.read<AuthProvider>().setBusinessId(business.id);
    } else {
      final error = context.read<BusinessProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create business: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(size: 72),
                  const SizedBox(height: 20),
                  Text('Set up your business', style: theme.textTheme.displayMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'A few details to get you started with Green Market',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GreenCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            prefixIcon: Icon(MingCute.store_line),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty ? 'Business name is required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'Your City',
                            prefixIcon: Icon(MingCute.building_2_line),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty ? 'City is required' : null,
                        ),
                        const SizedBox(height: 20),
                        Text('Business Type', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'single', label: Text('Single Owner')),
                            ButtonSegment(value: 'multi_partner', label: Text('Multi Partner')),
                          ],
                          selected: {_businessType},
                          onSelectionChanged: (v) => setState(() => _businessType = v.first),
                          style: SegmentedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Continue to Dashboard'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
