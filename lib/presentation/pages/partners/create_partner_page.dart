import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/green_card.dart';

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
  String _memberType = 'employee';
  String _role = 'purchaser';
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
      'member_type': _memberType,
      'access_level': _accessLevel,
      'manage_other_side': _manageOtherSide,
      'business_id': businessId,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (partner != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _memberType == 'employee'
                ? 'Employee added successfully'
                : 'Partner added successfully',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      final err = context.read<PartnerProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Could not create partner'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentBusiness =
        auth.businesses.where((b) => b.id == auth.businessId).firstOrNull;
    final isSoloBusiness = currentBusiness?.businessType == 'single';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isSoloBusiness ? 'Add Team Member' : 'Add Team / Partner',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GreenCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member Information & Role',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isSoloBusiness) ...[
                      Text(
                        'Member Classification',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Staff / Employee'),
                              selected: _memberType == 'employee',
                              onSelected: (_) => setState(() {
                                _memberType = 'employee';
                                if (_role == 'partner') _role = 'purchaser';
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Business Partner'),
                              selected: _memberType == 'partner',
                              onSelected: (_) => setState(() {
                                _memberType = 'partner';
                                _role = 'partner';
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(HeroIcons.information_circle, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Single-Owner Business: Members are created as Staff / Employees with scoped operational permissions.',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name (required)',
                        hintText: 'e.g. Aslam Khan',
                        prefixIcon: Icon(HeroIcons.user, size: 20),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter member name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (required)',
                        hintText: '03001234567',
                        prefixIcon: Icon(HeroIcons.phone, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone is required for linking account';
                        return Validators.phone(v);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City / Station',
                        hintText: 'e.g. Sargodha, Multan',
                        prefixIcon: Icon(HeroIcons.map_pin, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppDropdown<String>(
                      value: _role,
                      labelText: _memberType == 'employee' ? 'Operational Role' : 'Partner Role',
                      items: _memberType == 'employee'
                          ? const [
                              DropdownItem(
                                value: 'purchaser',
                                child: Text('Purchaser (Procurement & Transport)'),
                              ),
                              DropdownItem(
                                value: 'seller',
                                child: Text('Seller (Sales & Customer Dues)'),
                              ),
                              DropdownItem(
                                value: 'accountant',
                                child: Text('Accountant (Expenses & Ledgers)'),
                              ),
                              DropdownItem(
                                value: 'both',
                                child: Text('Manager (Both Purchasing & Selling)'),
                              ),
                            ]
                          : const [
                              DropdownItem(
                                value: 'partner',
                                child: Text('Partner (Equity Co-Owner)'),
                              ),
                              DropdownItem(
                                value: 'purchaser',
                                child: Text('Purchaser Partner (Managing Sourcing)'),
                              ),
                              DropdownItem(
                                value: 'seller',
                                child: Text('Seller Partner (Managing Mandi Sales)'),
                              ),
                              DropdownItem(
                                value: 'both',
                                child: Text('Active Executive Partner (Full Access)'),
                              ),
                            ],
                      onChanged: (value) => setState(() =>
                          _role = value ?? (_memberType == 'employee' ? 'purchaser' : 'partner')),
                    ),
                    const SizedBox(height: 14),
                    AppDropdown<String>(
                      value: _accessLevel,
                      labelText: 'Access Authority Level',
                      items: const [
                        DropdownItem(value: 'viewer', child: Text('Viewer (Scoped Operations)')),
                        DropdownItem(value: 'editor', child: Text('Editor (Full Edit & Advance)')),
                      ],
                      onChanged: (value) => setState(() => _accessLevel = value ?? 'viewer'),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Allow cross-side editing',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        'Grants write access on both Purchaser & Seller operations.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      value: _manageOtherSide,
                      onChanged: (value) => setState(() => _manageOtherSide = value),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                'Save Member Profile',
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
            ],
          ),
        ),
      ),
    );
  }
}
