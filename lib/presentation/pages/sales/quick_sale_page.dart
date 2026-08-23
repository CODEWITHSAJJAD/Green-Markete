import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/measurement_unit_provider.dart';
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
  final _qtyUnitKgCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceUnitKgCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _bankRefCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  BatchModel? _selectedBatch;
  CustomerModel? _selectedCustomer;
  String _paymentMode = 'cash';
  String _qtyUnitKey = 'kg';
  String _priceUnitKey = 'kg';
  bool _saving = false;

  List<PurchaseUnit> _customUnits(BuildContext context) => context
      .watch<MeasurementUnitProvider>()
      .units
      .map((u) => PurchaseUnit(u.id, u.name, u.kgPerUnit))
      .toList();

  /// The kg weight one unit of the selling unit represents — 1 when selling
  /// straight in kg, or a lot size (e.g. a 5kg bag) when the quantity is
  /// counted in units rather than weighed out.
  double _qtyUnitKgFor(List<PurchaseUnit> customUnits) {
    if (_qtyUnitKey == 'custom') {
      return double.tryParse(_qtyUnitKgCtrl.text.trim()) ?? 0;
    }
    return resolvePurchaseUnit(_qtyUnitKey, customUnits).kgPerUnit;
  }

  /// The actual kg quantity being sold — what gets checked against remaining
  /// batch stock and stored, regardless of what unit it was counted in.
  double _actualKgQuantity(List<PurchaseUnit> customUnits) {
    final entered = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    return entered * _qtyUnitKgFor(customUnits);
  }

  /// The kg weight the entered price is quoted against — 1 when priced
  /// straight per kg, or a supplier lot size (e.g. 40kg mann) when the
  /// seller only knows the price for that lot, not the per-kg rate.
  double _priceUnitKgFor(List<PurchaseUnit> customUnits) {
    if (_priceUnitKey == 'custom') {
      return double.tryParse(_priceUnitKgCtrl.text.trim()) ?? 0;
    }
    return resolvePurchaseUnit(_priceUnitKey, customUnits).kgPerUnit;
  }

  /// The actual per-kg price used to compute the total — the entered price
  /// divided by the unit it was quoted against.
  double _effectivePricePerKg(List<PurchaseUnit> customUnits) {
    final entered = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final kgPerUnit = _priceUnitKgFor(customUnits);
    return kgPerUnit > 0 ? entered / kgPerUnit : 0;
  }

  double _totalAmount(List<PurchaseUnit> customUnits) =>
      _actualKgQuantity(customUnits) * _effectivePricePerKg(customUnits);

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
      context.read<MeasurementUnitProvider>().load(businessId);
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _qtyUnitKgCtrl.dispose();
    _priceCtrl.dispose();
    _priceUnitKgCtrl.dispose();
    _cashCtrl.dispose();
    _bankRefCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBatch == null) return;
    final auth = context.read<AuthProvider>();
    final customUnits = context
        .read<MeasurementUnitProvider>()
        .units
        .map((u) => PurchaseUnit(u.id, u.name, u.kgPerUnit))
        .toList();
    final quantity = _actualKgQuantity(customUnits);
    final price = _effectivePricePerKg(customUnits);
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity and selling unit')),
      );
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price and pricing unit')),
      );
      return;
    }
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
                Builder(
                  builder: (context) {
                    final customUnits = _customUnits(context);
                    final actualKg = _actualKgQuantity(customUnits);
                    final pricePerKg = _effectivePricePerKg(customUnits);
                    final total = _totalAmount(customUnits);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(labelText: 'Quantity Sold *'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  if (double.tryParse(v.trim()) == null) return 'Invalid';
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
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
                                  labelText: _priceUnitKey == 'kg' ? 'Price / kg *' : 'Price / unit *',
                                  prefixText: '${CurrencyFormatter.currentCode} ',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  if (double.tryParse(v.trim()) == null) return 'Invalid';
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Units',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppDropdown<String>(
                                      value: _qtyUnitKey,
                                      labelText: 'Selling unit',
                                      fillColor: AppColors.surface,
                                      items: [
                                        for (final u in purchaseUnits)
                                          DropdownItem(value: u.key, child: Text(u.label)),
                                        for (final u in customUnits)
                                          DropdownItem(value: u.key, child: Text(u.label)),
                                        const DropdownItem(value: 'custom', child: Text('Custom weight')),
                                      ],
                                      onChanged: (v) => setState(() => _qtyUnitKey = v ?? 'kg'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AppDropdown<String>(
                                      value: _priceUnitKey,
                                      labelText: 'Price quoted per',
                                      fillColor: AppColors.surface,
                                      items: [
                                        for (final u in purchaseUnits)
                                          DropdownItem(value: u.key, child: Text(u.label)),
                                        for (final u in customUnits)
                                          DropdownItem(value: u.key, child: Text(u.label)),
                                        const DropdownItem(value: 'custom', child: Text('Custom weight')),
                                      ],
                                      onChanged: (v) => setState(() => _priceUnitKey = v ?? 'kg'),
                                    ),
                                  ),
                                ],
                              ),
                              if (_qtyUnitKey == 'custom') ...[
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _qtyUnitKgCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Weight of one unit sold (kg) *',
                                    filled: false,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                              if (_priceUnitKey == 'custom') ...[
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _priceUnitKgCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Lot weight the price covers (kg) *',
                                    filled: false,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                              if (_qtyUnitKey != 'kg' || _priceUnitKey != 'kg') ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                if (_qtyUnitKey != 'kg')
                                  _conversionLine(
                                    'Quantity in kg',
                                    actualKg > 0 ? '${actualKg.toStringAsFixed(2)} kg' : '—',
                                  ),
                                if (_priceUnitKey != 'kg')
                                  Padding(
                                    padding: EdgeInsets.only(top: _qtyUnitKey != 'kg' ? 4 : 0),
                                    child: _conversionLine(
                                      'Rate per kg',
                                      pricePerKg > 0 ? CurrencyFormatter.format(pricePerKg) : '—',
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  CurrencyFormatter.format(total),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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

  Widget _conversionLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
