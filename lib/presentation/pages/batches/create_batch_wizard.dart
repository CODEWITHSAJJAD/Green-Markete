import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/market_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/batch_wizard_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/market_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/partner_selector.dart';
import '../../widgets/packing_entry_form.dart';
import '../../../data/models/vehicle_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CreateBatchWizard extends StatefulWidget {
  const CreateBatchWizard({super.key});

  @override
  State<CreateBatchWizard> createState() => _CreateBatchWizardState();
}

class _CreateBatchWizardState extends State<CreateBatchWizard> {
  final PageController _pageCtrl = PageController();
  bool _submitting = false;

  // Step 1
  String? _productId;
  String? _productName;
  String? _sourceMarketId;
  String? _destinationMarketId;
  DateTime _purchaseDate = DateTime.now();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  String _unit = 'kg';
  String _transportPaidBy = 'purchaser';
  String _purchasePaymentMode = 'cash';

  // Step 2
  List<Map<String, dynamic>> _partners = [];
  String? _sellerId;

  // Step 3
  List<Map<String, dynamic>> _packing = [];

  // Step 4
  final List<Map<String, dynamic>> _expenses = [];

  // Step 5
  final List<Map<String, dynamic>> _vehicleLoads = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BatchWizardProvider>().setStep(0);
      final businessId = context.read<AuthProvider>().businessId;
      if (businessId != null && businessId.isNotEmpty) {
        context.read<ProductProvider>().load(businessId);
        context.read<MarketProvider>().load(businessId);
        context.read<PartnerProvider>().load(businessId);
        context.read<VehicleProvider>().load(businessId);
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _supplierCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final wizard = context.read<BatchWizardProvider>();
    if (wizard.currentStep < 5) {
      wizard.nextStep();
      _pageCtrl.animateToPage(
        wizard.currentStep,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }
  }

  void _prev() {
    final wizard = context.read<BatchWizardProvider>();
    if (wizard.currentStep > 0) {
      wizard.previousStep();
      _pageCtrl.animateToPage(
        wizard.currentStep,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _productId != null &&
            _sourceMarketId != null &&
            _quantityCtrl.text.trim().isNotEmpty &&
            _priceCtrl.text.trim().isNotEmpty;
      case 1:
        return _partners.isNotEmpty &&
            _partners.first['partner_id'] != null &&
            _sellerId != null;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  }

  /// Generate a unique batch code on the frontend. The DB trigger that
  /// auto-generates `GM-YYYY-NNNN` has a race condition between its
  /// SELECT MAX and INSERT, so we send our own unique value. If the trigger
  /// is conditional (`IF NEW.batch_code IS NULL`), it skips generation and
  /// uses ours.
  String _generateBatchCode() {
    final now = DateTime.now();
    final year = now.year;
    final suffix = Random()
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return 'GM-$year-$suffix';
  }

  Future<void> _submit() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    final totalQty = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final pricePerUnit = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final paidAmount = double.tryParse(_paidCtrl.text.trim()) ?? 0;

    final payload = BatchCreateRequest(
      businessId: businessId,
      productId: _productId!,
      sourceMarketId: _sourceMarketId,
      destinationMarketId: _destinationMarketId,
      batchCode: _generateBatchCode(),
      purchaseDate: _purchaseDate.toIso8601String().split('T').first,
      totalQuantity: totalQty,
      quantityUnit: _unit,
      purchasePricePerUnit: pricePerUnit,
      transportPaidBy: _transportPaidBy,
      supplierName: _supplierCtrl.text.trim().isEmpty
          ? null
          : _supplierCtrl.text.trim(),
      purchasePaymentMode: _purchasePaymentMode,
      purchaseAmountPaid: paidAmount,
      partners: [
        ..._partners
            .where((p) => p['partner_id'] != null)
            .map(
              (p) => BatchPartnerCreate(
                partnerId: p['partner_id'] as String,
                role: p['role'] as String,
                dailyChargeRate:
                    (p['daily_charge_rate'] as num?)?.toDouble() ?? 0,
                daysInvolved: (p['days_involved'] as int?) ?? 1,
              ),
            ),
        if (_sellerId != null)
          BatchPartnerCreate(
            partnerId: _sellerId!,
            role: 'seller',
            dailyChargeRate: 0,
            daysInvolved: 1,
          ),
      ],
      packingRecords: _packing
          .where((p) => (p['unit_count'] as int) > 0)
          .map(
            (p) => PackingRecordCreate(
              unitType: p['unit_type'] as String,
              unitLabel: p['unit_label'] as String?,
              unitCount: p['unit_count'] as int,
              costPerUnit: (p['cost_per_unit'] as num).toDouble(),
            ),
          )
          .toList(),
      expenses: _expenses
          .where((e) => (e['amount'] as double) > 0)
          .map(
            (e) => ExpenseCreate(
              partnerId: e['partner_id'] as String?,
              expenseSide: e['expense_side'] as String,
              expenseType: e['expense_type'] as String,
              amount: (e['amount'] as num).toDouble(),
              description: e['description'] as String?,
              paidBy: e['paid_by'] as String?,
              paymentMode: e['payment_mode'] as String?,
              paymentReference: e['payment_reference'] as String?,
              expenseDate: e['expense_date'] as String?,
            ),
          )
          .toList(),
      vehicleLoads: _vehicleLoads
          .where((v) => v['vehicle_id'] != null)
          .map(
            (v) => VehicleLoadCreate(
              vehicleId: v['vehicle_id'] as String,
              packingRecordIndex: v['packing_index'] as int?,
              unitCount: double.tryParse(v['unit_count'].toString()) ?? 0,
              costType: v['cost_type'] as String,
              transportCost:
                  double.tryParse(v['transport_cost'].toString()) ?? 0,
              loadDate: _purchaseDate.toIso8601String().split('T').first,
            ),
          )
          .toList(),
    );

    setState(() => _submitting = true);
    try {
      final ok = await context.read<BatchListProvider>().create(payload);
      if (!mounted) return;
      if (ok) {
        await _createTransportDebt(businessId);
        if (!mounted) return;
        DataRefreshNotifier.instance.refresh(businessId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Batch created')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<BatchListProvider>().error ??
                  'Failed to create batch',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createTransportDebt(String businessId) async {
    if (_transportPaidBy != 'seller') return;
    if (_sellerId == null) return;
    final purchaserId =
        _partners.firstWhere(
              (p) => p['partner_id'] != null,
              orElse: () => {},
            )['partner_id']
            as String?;
    if (purchaserId == null) return;
    if (purchaserId == _sellerId) return;
    final transportTotal = _expenses.fold<double>(
      0,
      (acc, e) => e['expense_side'] == 'transport'
          ? acc + ((e['amount'] as num?)?.toDouble() ?? 0)
          : acc,
    );
    if (transportTotal <= 0) return;
    await context.read<TransactionProvider>().create(
      TransactionCreateRequest(
        businessId: businessId,
        fromPartnerId: purchaserId,
        toPartnerId: _sellerId!,
        amount: transportTotal,
        transactionType: 'transport_debt',
        transactionDate: DateTime.now().toIso8601String().split('T').first,
        notes: 'Auto: seller paid transport for ${_generateBatchCode()}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = context.watch<BatchWizardProvider>().currentStep;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Batch Wizard'),
        leading: IconButton(
          icon: const Icon(MingCuteIcons.mgc_close_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${step + 1} of 6',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: (step + 1) / 6),
                const SizedBox(height: 8),
                Text(_stepTitle(step), style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _step1(theme),
                _step2(),
                _step3(),
                _step4(),
                _stepTransport(theme),
                _step5(theme),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _prev,
                        child: const Text('Back'),
                      ),
                    ),
                  if (step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting || !_validateStep(step)
                          ? null
                          : () {
                              if (step == 5) {
                                _submit();
                              } else {
                                _next();
                              }
                            },
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(step == 5 ? 'Confirm & Create' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int s) {
    switch (s) {
      case 0:
        return 'Product & Purchase';
      case 1:
        return 'Purchasing Partners';
      case 2:
        return 'Packing';
      case 3:
        return 'Purchaser Expenses';
      case 4:
        return 'Transport & Loads';
      case 5:
        return 'Review & Confirm';
      default:
        return '';
    }
  }

  Widget _step1(ThemeData theme) {
    final productsProvider = context.watch<ProductProvider>();
    final marketsProvider = context.watch<MarketProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          productsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productsProvider.error != null
              ? Text(productsProvider.error!)
              : _productDropdown(theme, productsProvider.products),
          const SizedBox(height: 16),
          Text('Markets', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          marketsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : marketsProvider.error != null
              ? Text(marketsProvider.error!)
              : Column(
                  children: [
                    _marketDropdown(
                      theme,
                      marketsProvider.markets,
                      isSource: true,
                    ),
                    const SizedBox(height: 12),
                    _marketDropdown(
                      theme,
                      marketsProvider.markets,
                      isSource: false,
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          Text('Purchase Date', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _purchaseDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _purchaseDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(MingCuteIcons.mgc_calendar_3_line, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField2<String>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(_unit),
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownItem(value: 'kg', child: Text('kg')),
                    DropdownItem(value: 'g', child: Text('g')),
                    DropdownItem(value: 'L', child: Text('L')),
                    DropdownItem(value: 'pcs', child: Text('pcs')),
                    DropdownItem(value: 'bag', child: Text('bag')),
                    DropdownItem(value: 'crate', child: Text('crate')),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price per unit'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            'Total: ${CurrencyFormatter.format((double.tryParse(_quantityCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0))}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Text('Supplier', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _supplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Supplier name',
              hintText: 'e.g. Ahmed Brothers, Karachi market',
            ),
          ),
          const SizedBox(height: 16),
          Text('Purchase Payment', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField2<String>(
            isExpanded: true,
            valueListenable: ValueNotifier(_purchasePaymentMode),
            decoration: const InputDecoration(labelText: 'Payment mode'),
            items: const [
              DropdownItem(
                value: 'cash',
                child: Text(
                  'Cash',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              DropdownItem(
                value: 'credit',
                child: Text(
                  'Credit / Debt',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              DropdownItem(
                value: 'part_credit',
                child: Text(
                  'Part cash / part credit',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
            onChanged: (v) =>
                setState(() => _purchasePaymentMode = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paidCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount paid now'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final purchaseTotal =
                  (double.tryParse(_quantityCtrl.text) ?? 0) *
                  (double.tryParse(_priceCtrl.text) ?? 0);
              final paid = double.tryParse(_paidCtrl.text) ?? 0;
              final remaining = (purchaseTotal - paid).clamp(
                0,
                double.infinity,
              );
              return Text(
                'Remaining payable: ${CurrencyFormatter.format(remaining)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: remaining > 0
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Transport Paid By', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'purchaser', label: Text('Purchaser')),
              ButtonSegment(value: 'seller', label: Text('Seller')),
            ],
            selected: {_transportPaidBy},
            onSelectionChanged: (v) =>
                setState(() => _transportPaidBy = v.first),
          ),
        ],
      ),
    );
  }

  Widget _productDropdown(ThemeData theme, List<ProductModel> products) {
    return DropdownButtonFormField2<String>(
      isExpanded: true,
      valueListenable: ValueNotifier(_productId),
      decoration: const InputDecoration(labelText: 'Select product'),
      items: products
          .map(
            (p) => DropdownItem(
              value: p.id,
              child: Text(p.name, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          final p = products.firstWhere((x) => x.id == v);
          setState(() {
            _productId = v;
            _productName = p.name;
            _unit = p.baseUnit;
          });
        }
      },
    );
  }

  Widget _marketDropdown(
    ThemeData theme,
    List<MarketModel> markets, {
    required bool isSource,
  }) {
    return DropdownButtonFormField2<String>(
      isExpanded: true,
      valueListenable: ValueNotifier(
        isSource ? _sourceMarketId : _destinationMarketId,
      ),
      decoration: InputDecoration(
        labelText: isSource ? 'Source market' : 'Destination market',
      ),
      items: markets
          .map(
            (m) => DropdownItem(
              value: m.id,
              child: Text(
                '${m.name} â€¢ ${m.city}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          if (isSource) {
            _sourceMarketId = v;
          } else {
            _destinationMarketId = v;
          }
        });
      },
    );
  }

  Widget _step2() {
    final partners = context.watch<PartnerProvider>().partners;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add at least one purchasing partner. Daily charge Ã— days will be added to cost automatically.',
          ),
          const SizedBox(height: 16),
          PartnerSelector(
            selectedPartners: const <PartnerModel>[],
            businessId: context.read<AuthProvider>().businessId ?? '',
            onChanged: (partners) => setState(() => _partners = partners),
          ),
          const SizedBox(height: 24),
          Text(
            'Selling Partner',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          partners.isEmpty
              ? const Text(
                  'No partners yet. Add at least one purchasing partner above first.',
                  style: TextStyle(color: Colors.grey),
                )
              : DropdownButtonFormField2<String>(
                  isExpanded: true,
                  valueListenable: ValueNotifier(_sellerId),
                  decoration: const InputDecoration(
                    labelText: 'Select the selling partner',
                  ),
                  items: partners
                      .map(
                        (p) => DropdownItem(
                          value: p.id,
                          child: Text(
                            p.fullName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _sellerId = v),
                ),
        ],
      ),
    );
  }

  Widget _step3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add packing records (optional). Total cost = count Ã— cost per unit.',
          ),
          const SizedBox(height: 16),
          PackingEntryForm(
            entries: const [],
            onChanged: (records) => _packing = records,
          ),
        ],
      ),
    );
  }

  Widget _step4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add expenses (optional). These will appear in batch P&L breakdown.',
          ),
          const SizedBox(height: 16),
          _expenseList(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addExpense,
              icon: const Icon(MingCuteIcons.mgc_add_line),
              label: const Text('Add expense'),
            ),
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    setState(
      () => _expenses.add({
        'expense_side': _transportPaidBy == 'purchaser'
            ? 'purchaser'
            : 'transport',
        'expense_type': 'misc',
        'amount': 0.0,
        'description': null,
        'paid_by': null,
        'payment_mode': 'cash',
        'payment_reference': null,
        'expense_date': DateTime.now().toIso8601String().split('T').first,
      }),
    );
  }

  Widget _expenseList() {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(_expenses.length, (i) {
        final e = _expenses[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      isExpanded: true,
                      valueListenable: ValueNotifier(
                        e['expense_side'] as String,
                      ),
                      decoration: const InputDecoration(labelText: 'Side'),
                      items: const [
                        DropdownItem(
                          value: 'purchaser',
                          child: Text(
                            'Purchaser',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'transport',
                          child: Text(
                            'Transport',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'seller',
                          child: Text(
                            'Seller',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => e['expense_side'] = v ?? 'purchaser'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      isExpanded: true,
                      valueListenable: ValueNotifier(
                        e['expense_type'] as String,
                      ),
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownItem(
                          value: 'daily_charge',
                          child: Text(
                            'Daily Charge',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'labor',
                          child: Text(
                            'Labor',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'accountant',
                          child: Text(
                            'Accountant',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'source_stall_fee',
                          child: Text(
                            'Stall Fee (source)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'destination_stall_fee',
                          child: Text(
                            'Stall Fee (destination)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'transport',
                          child: Text(
                            'Transport',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'local_transport',
                          child: Text(
                            'Local Transport',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'misc',
                          child: Text(
                            'Misc',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => e['expense_type'] = v ?? 'misc'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(MingCuteIcons.mgc_delete_3_line),
                    onPressed: () => setState(() => _expenses.removeAt(i)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: e['amount'].toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                onChanged: (v) => e['amount'] = double.tryParse(v) ?? 0.0,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: e['description']?.toString(),
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (v) => e['description'] = v.isEmpty ? null : v,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      isExpanded: true,
                      valueListenable: ValueNotifier(
                        e['payment_mode'] as String,
                      ),
                      decoration: const InputDecoration(labelText: 'Payment'),
                      items: const [
                        DropdownItem(
                          value: 'cash',
                          child: Text(
                            'Cash',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        DropdownItem(
                          value: 'bank_transfer',
                          child: Text(
                            'Bank Transfer',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => e['payment_mode'] = v ?? 'cash'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: e['expense_date']?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                      ),
                      onChanged: (v) => e['expense_date'] = v.isEmpty
                          ? DateTime.now().toIso8601String().split('T').first
                          : v,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _stepTransport(ThemeData theme) {
    final vehicles = context.watch<VehicleProvider>().vehicles;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Split the batch across vehicles. Linked loads split shared transport fairly between packing records.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (vehicles.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(MingCuteIcons.mgc_information_line, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No vehicles registered yet. Add them from Manage â†’ Vehicles, or skip this step.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...List.generate(_vehicleLoads.length, (i) {
              final load = _vehicleLoads[i];
              return _transportLoadCard(theme, i, load, vehicles);
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _vehicleLoads.add({
                  'vehicle_id': null,
                  'packing_index': null,
                  'unit_count': '0',
                  'cost_type': 'per_vehicle',
                  'transport_cost': '0',
                });
              }),
              icon: const Icon(MingCuteIcons.mgc_add_line),
              label: const Text('Add vehicle load'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transportLoadCard(
    ThemeData theme,
    int index,
    Map<String, dynamic> load,
    List<VehicleModel> vehicles,
  ) {
    final packing = _packing;
    return Container(
      key: ValueKey('load-$index'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Load ${index + 1}', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(MingCuteIcons.mgc_close_line, size: 18),
                onPressed: () => setState(() => _vehicleLoads.removeAt(index)),
              ),
            ],
          ),
          DropdownButtonFormField2<String>(
            isExpanded: true,
            valueListenable: ValueNotifier(load['vehicle_id'] as String?),
            decoration: const InputDecoration(labelText: 'Vehicle'),
            items: [
              for (final v in vehicles)
                DropdownItem(
                  value: v.id,
                  child: Text(v.plateNumber, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => load['vehicle_id'] = v),
          ),
          if (packing.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField2<int>(
              isExpanded: true,
              valueListenable: ValueNotifier(load['packing_index'] as int?),
              decoration: const InputDecoration(
                labelText: 'Packing record (optional)',
              ),
              items: [
                for (var i = 0; i < packing.length; i++)
                  DropdownItem(
                    value: i,
                    child: Text(
                      '${i + 1}. ${packing[i]['unit_type']} Ã— ${packing[i]['unit_count']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => load['packing_index'] = v),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            initialValue: load['unit_count'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Units loaded'),
            onChanged: (v) => setState(() => load['unit_count'] = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField2<String>(
            isExpanded: true,
            valueListenable: ValueNotifier(load['cost_type'] as String),
            decoration: const InputDecoration(labelText: 'Cost type'),
            items: const [
              DropdownItem(
                value: 'per_vehicle',
                child: Text('Flat per vehicle'),
              ),
              DropdownItem(
                value: 'per_packing',
                child: Text('Per unit loaded'),
              ),
              DropdownItem(value: 'lump_sum', child: Text('Lump sum')),
            ],
            onChanged: (v) =>
                setState(() => load['cost_type'] = v ?? 'per_vehicle'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: load['transport_cost'].toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: load['cost_type'] == 'per_packing'
                  ? 'Transport cost per unit'
                  : 'Transport cost',
            ),
            onChanged: (v) => setState(() => load['transport_cost'] = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${CurrencyFormatter.format(_loadTotal(load))}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  double _loadTotal(Map<String, dynamic> load) {
    final cost = double.tryParse(load['transport_cost'].toString()) ?? 0;
    final units = double.tryParse(load['unit_count'].toString()) ?? 0;
    return load['cost_type'] == 'per_packing' ? units * cost : cost;
  }

  Widget _step5(ThemeData theme) {
    final qty = double.tryParse(_quantityCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final purchaseCost = qty * price;
    final packingCost = _packing.fold<double>(0, (acc, p) {
      final count = (p['unit_count'] as int?) ?? 0;
      final cost = (p['cost_per_unit'] as num?)?.toDouble() ?? 0;
      return acc + count * cost;
    });
    final expenseCost = _expenses.fold<double>(
      0,
      (acc, e) => acc + ((e['amount'] as num?)?.toDouble() ?? 0),
    );
    final dailyCharges = _partners.fold<double>(0, (acc, p) {
      final rate = (p['daily_charge_rate'] as num?)?.toDouble() ?? 0;
      final days = (p['days_involved'] as int?) ?? 1;
      return acc + rate * days;
    });
    final transportLoadCost = _vehicleLoads.fold<double>(
      0,
      (acc, v) => acc + _loadTotal(v),
    );
    final total =
        purchaseCost +
        packingCost +
        expenseCost +
        dailyCharges +
        transportLoadCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _summaryRow('Product', _productName ?? '-'),
                _summaryRow('Quantity', '$qty $_unit'),
                _summaryRow(
                  'Supplier',
                  _supplierCtrl.text.trim().isEmpty
                      ? '-'
                      : _supplierCtrl.text.trim(),
                ),
                _summaryRow(
                  'Purchase payment',
                  _purchasePaymentMode == 'cash'
                      ? 'Cash'
                      : _purchasePaymentMode == 'credit'
                      ? 'Credit'
                      : 'Part cash / credit',
                ),
                if ((double.tryParse(_paidCtrl.text) ?? 0) > 0)
                  _summaryRow(
                    'Paid now',
                    CurrencyFormatter.format(
                      double.tryParse(_paidCtrl.text) ?? 0,
                    ),
                  ),
                _summaryRow(
                  'Purchase cost',
                  CurrencyFormatter.format(purchaseCost),
                ),
                _summaryRow('Partners', '${_partners.length}'),
                _summaryRow(
                  'Daily charges',
                  CurrencyFormatter.format(dailyCharges),
                ),
                _summaryRow('Packing', CurrencyFormatter.format(packingCost)),
                _summaryRow('Expenses', CurrencyFormatter.format(expenseCost)),
                _summaryRow('Vehicle loads', '${_vehicleLoads.length}'),
                _summaryRow(
                  'Transport loads',
                  CurrencyFormatter.format(transportLoadCost),
                ),
                const Divider(height: 24),
                _summaryRow(
                  'Total estimated cost',
                  CurrencyFormatter.format(total),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(MingCuteIcons.mgc_information_line, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backend will auto-generate a batch code (GM-YYYY-NNNN) and recompute totals.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
