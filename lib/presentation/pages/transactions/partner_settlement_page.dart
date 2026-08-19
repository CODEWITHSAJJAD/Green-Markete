import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/green_card.dart';

class PartnerSettlementPage extends StatefulWidget {
  const PartnerSettlementPage({super.key});

  @override
  State<PartnerSettlementPage> createState() => _PartnerSettlementPageState();
}

class _PartnerSettlementPageState extends State<PartnerSettlementPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _fromPartnerId;
  String? _toPartnerId;
  String _paymentMode = 'cash';
  String _transactionType = 'settlement';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final businessId = context.read<AuthProvider>().businessId ?? '';
      if (businessId.isNotEmpty) {
        context.read<PartnerProvider>().load(businessId);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId ?? '';
    final partnerProvider = context.watch<PartnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Record Partner Settlement',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: partnerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : partnerProvider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(HeroIcons.wifi, size: 44, color: AppColors.rose),
                        const SizedBox(height: 12),
                        Text(partnerProvider.error!, style: GoogleFonts.inter(color: AppColors.rose)),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => partnerProvider.load(businessId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GreenCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Settlement Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppDropdown<String>.fromList(
                              value: _fromPartnerId,
                              labelText: 'From Partner (Payer)',
                              items: partnerProvider.partners.map((p) => p.id).toList(),
                              itemLabel: (id) => partnerProvider.partners.firstWhere((p) => p.id == id).fullName,
                              onChanged: (value) => setState(() => _fromPartnerId = value),
                              validator: (value) => value == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            AppDropdown<String>.fromList(
                              value: _toPartnerId,
                              labelText: 'To Partner (Recipient / Seller)',
                              items: partnerProvider.partners.map((p) => p.id).toList(),
                              itemLabel: (id) => partnerProvider.partners.firstWhere((p) => p.id == id).fullName,
                              onChanged: (value) => setState(() => _toPartnerId = value),
                              validator: (value) => value == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Settlement Amount',
                                prefixIcon: Icon(HeroIcons.banknotes, size: 20),
                              ),
                              validator: (value) => Validators.positiveNumber(value, 'Amount'),
                            ),
                            const SizedBox(height: 14),
                            AppDropdown<String>(
                              value: _transactionType,
                              labelText: 'Transaction Type',
                              items: const [
                                DropdownItem(value: 'settlement', child: Text('Batch Settlement')),
                                DropdownItem(value: 'advance', child: Text('Advance Payment')),
                                DropdownItem(value: 'expense_reimbursement', child: Text('Expense Reimbursement')),
                              ],
                              onChanged: (value) => setState(() => _transactionType = value ?? 'settlement'),
                            ),
                            const SizedBox(height: 14),
                            AppDropdown<String>(
                              value: _paymentMode,
                              labelText: 'Payment Mode',
                              items: const [
                                DropdownItem(value: 'cash', child: Text('Cash')),
                                DropdownItem(value: 'bank_transfer', child: Text('Bank Transfer / Cheque')),
                              ],
                              onChanged: (value) => setState(() => _paymentMode = value ?? 'cash'),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _referenceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Reference / Cheque Number (optional)',
                                prefixIcon: Icon(HeroIcons.document_text, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _notesCtrl,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Notes / Batch Reference',
                                hintText: 'e.g. Settlement for batch GM-2026-X',
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) return;
                                        final messenger = ScaffoldMessenger.of(context);
                                        final navigator = Navigator.of(context);
                                        final txProvider = context.read<TransactionProvider>();
                                        setState(() => _isSaving = true);
                                        final transaction = await txProvider.create(
                                          TransactionCreateRequest(
                                            businessId: businessId,
                                            fromPartnerId: _fromPartnerId!,
                                            toPartnerId: _toPartnerId!,
                                            amount: double.parse(_amountCtrl.text.trim()),
                                            transactionType: _transactionType,
                                            paymentMode: _paymentMode,
                                            reference: _referenceCtrl.text.trim().isEmpty
                                                ? null
                                                : _referenceCtrl.text.trim(),
                                            transactionDate: DateTime.now().toIso8601String().split('T').first,
                                            notes: _notesCtrl.text.trim().isEmpty
                                                ? null
                                                : _notesCtrl.text.trim(),
                                          ),
                                        );
                                        if (!mounted) return;
                                        final errorText = txProvider.error ?? 'Unknown error';
                                        setState(() => _isSaving = false);
                                        if (transaction != null) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Settlement recorded successfully')),
                                          );
                                          navigator.pop();
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Could not save settlement: $errorText'),
                                              backgroundColor: AppColors.rose,
                                            ),
                                          );
                                        }
                                      },
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Save Settlement',
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
    );
  }
}
