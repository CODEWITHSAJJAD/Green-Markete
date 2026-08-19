import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/green_card.dart';

class RecordPaymentPage extends StatefulWidget {
  final CustomerModel customer;

  const RecordPaymentPage({super.key, required this.customer});

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMode = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount must be positive')));
      return;
    }
    if (amount > widget.customer.outstandingBalance + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds outstanding balance of ${CurrencyFormatter.format(widget.customer.outstandingBalance)}',
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final businessId = auth.businessId;
    if (businessId == null || businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active business selected')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final customerProv = context.read<CustomerProvider>();
      final payload = PaymentCreateRequest(
        customerId: widget.customer.id,
        businessId: businessId,
        amount: amount,
        paymentMode: _paymentMode,
        bankReference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        paymentDate: DateTime.now().toIso8601String().split('T').first,
      );

      final success = await customerProv.recordPayment(
        widget.customer.id,
        payload,
      );

      if (!mounted) return;
      if (success) {
        if (businessId.isNotEmpty) {
          context.read<SaleProvider>().loadByBusiness(businessId);
          DataRefreshNotifier.instance.refresh(businessId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customerProv.error ?? 'Failed to record payment'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final outstanding = widget.customer.outstandingBalance;
    final overLimit = amount > outstanding + 0.01;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Record Customer Payment',
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (outstanding > 0
                            ? AppColors.roseSurface
                            : AppColors.emeraldSurface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (outstanding > 0
                                      ? AppColors.rose
                                      : AppColors.emerald)
                                  .withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        outstanding > 0
                            ? HeroIcons.banknotes
                            : HeroIcons.check_badge,
                        color: outstanding > 0
                            ? AppColors.rose
                            : AppColors.emeraldDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outstanding > 0
                                ? 'Outstanding Customer Credit'
                                : 'No Outstanding Dues',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(outstanding),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: outstanding > 0
                                  ? AppColors.rose
                                  : AppColors.emeraldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GreenCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Payment Entry Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Payment Amount',
                        prefixIcon: const Icon(HeroIcons.banknotes, size: 20),
                        helperText: outstanding > 0
                            ? 'Maximum limit: ${CurrencyFormatter.format(outstanding)}'
                            : 'No balance owed',
                        errorText: overLimit
                            ? 'Exceeds outstanding balance'
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Required';
                        final v = double.tryParse(value.trim());
                        if (v == null || v <= 0)
                          return 'Enter a positive number';
                        if (v > outstanding + 0.01) {
                          return 'Exceeds outstanding balance';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    AppDropdown<String>(
                      value: _paymentMode,
                      labelText: 'Payment Mode',
                      items: const [
                        DropdownItem(
                          value: 'cash',
                          child: Text('Cash Received'),
                        ),
                        DropdownItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer / Deposit'),
                        ),
                        DropdownItem(
                          value: 'cheque',
                          child: Text('Cheque / PDC'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _paymentMode = v ?? 'cash'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _referenceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Reference / Bank Slip #',
                        prefixIcon: Icon(HeroIcons.document_text, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText:
                            'e.g. Cleared partial dues for last week purchase',
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                'Record Payment',
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
