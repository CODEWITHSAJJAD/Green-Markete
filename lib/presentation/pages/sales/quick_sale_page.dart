import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/green_card.dart';

class QuickSalePage extends StatefulWidget {
  final String? preselectedBatchId;

  const QuickSalePage({super.key, this.preselectedBatchId});

  @override
  State<QuickSalePage> createState() => _QuickSalePageState();
}

class _QuickSalePageState extends State<QuickSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _bankRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  BatchModel? _selectedBatch;
  CustomerModel? _selectedCustomer;
  String _paymentMode = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId != null && businessId.isNotEmpty) {
      context
          .read<BatchListProvider>()
          .load(businessId, status: 'selling')
          .then((_) {
            if (widget.preselectedBatchId != null && mounted) {
              final batches = context.read<BatchListProvider>().batches;
              final match = batches
                  .where((b) => b.id == widget.preselectedBatchId)
                  .firstOrNull;
              if (match != null) {
                setState(() => _selectedBatch = match);
              }
            }
          });
      context.read<CustomerProvider>().load(businessId);
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _cashCtrl.dispose();
    _bankRefCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBatch == null) return;
    final auth = context.read<AuthProvider>();
    final quantity = double.parse(_quantityCtrl.text.trim());
    final price = double.parse(_priceCtrl.text.trim());
    final cashReceived = _cashCtrl.text.trim().isEmpty
        ? 0.0
        : double.parse(_cashCtrl.text.trim());
    final totalAmount = quantity * price;
    final creditAmount = _paymentMode == 'partial_credit'
        ? (totalAmount - cashReceived)
        : _paymentMode == 'credit'
        ? totalAmount
        : 0.0;

    setState(() => _saving = true);
    final ok = await context.read<SaleProvider>().add(
      SaleCreateRequest(
        batchId: _selectedBatch!.id,
        sellerId: auth.userId,
        customerId: _selectedCustomer?.id,
        saleDate: DateTime.now().toIso8601String().split('T').first,
        quantitySold: quantity,
        pricePerUnit: price,
        paymentMode: _paymentMode,
        cashReceived: cashReceived,
        creditAmount: creditAmount,
        bankReference: _bankRefCtrl.text.trim().isEmpty
            ? null
            : _bankRefCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _load();
      final businessId = auth.businessId;
      if (businessId != null && businessId.isNotEmpty) {
        DataRefreshNotifier.instance.refresh(businessId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<SaleProvider>().error ?? 'Failed to record sale',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchesProvider = context.watch<BatchListProvider>();
    final customersProvider = context.watch<CustomerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Record Wholesale Order',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
      ),
      body: _buildBody(context, batchesProvider, customersProvider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BatchListProvider batchesProvider,
    CustomerProvider customersProvider,
  ) {
    if (batchesProvider.isLoading || customersProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final batches = batchesProvider.batches;
    final customers = customersProvider.customers;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          GreenCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Parameters',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                AppDropdown<BatchModel>.fromList(
                  value: _selectedBatch,
                  labelText: 'Select Selling Batch *',
                  prefixIcon: const Icon(HeroIcons.cube, size: 18),
                  items: batches,
                  itemLabel: (b) =>
                      '#${b.batchCode} - ${b.productName ?? 'Product'} (${b.totalQuantity.toStringAsFixed(0)} ${b.quantityUnit})',
                  onChanged: (val) => setState(() => _selectedBatch = val),
                  validator: (v) => v == null ? 'Please select a batch' : null,
                ),
                const SizedBox(height: 14),
                AppDropdown<CustomerModel?>(
                  value: _selectedCustomer,
                  labelText: 'Customer / Customer (Optional for Walk-in)',
                  prefixIcon: const Icon(HeroIcons.user, size: 18),
                  items: [
                    const DropdownItem<CustomerModel?>(
                      value: null,
                      child: Text('Direct Walk-in Customer'),
                    ),
                    ...customers.map(
                      (c) => DropdownItem<CustomerModel?>(
                        value: c,
                        child: Text(
                          '${c.fullName}${c.shopName != null ? ' (${c.shopName})' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Quantity Sold *',
                          suffixText: _selectedBatch?.quantityUnit ?? 'units',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null)
                            return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Price / Unit *',
                          prefixText: '${CurrencyFormatter.currentCode} ',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null)
                            return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  value: _paymentMode,
                  labelText: 'Settlement Terms *',
                  prefixIcon: const Icon(HeroIcons.credit_card, size: 18),
                  items: const [
                    DropdownItem(
                      value: 'cash',
                      child: Text('Full Cash Payment'),
                    ),
                    DropdownItem(
                      value: 'credit',
                      child: Text('Full Credit (Customer Account)'),
                    ),
                    DropdownItem(
                      value: 'partial_credit',
                      child: Text('Split Cash & Credit'),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _paymentMode = val ?? 'cash'),
                ),
                if (_paymentMode == 'partial_credit') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cashCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Cash Paid Upfront *',
                      prefixText: '${CurrencyFormatter.currentCode} ',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dispatch / Order Notes (Optional)',
                    prefixIcon: Icon(HeroIcons.document_text, size: 18),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(HeroIcons.check_circle, size: 20),
              label: Text(
                _saving ? 'Recording...' : 'Confirm & Save Sale',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
