import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/config/theme.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/batch_wizard_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/market_provider.dart';
import '../../providers/partner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/batches/wizard_basic_info_step.dart';
import '../../widgets/batches/wizard_expenses_step.dart';
import '../../widgets/batches/wizard_packing_step.dart';
import '../../widgets/batches/wizard_partners_step.dart';
import '../../widgets/batches/wizard_review_step.dart';
import '../../widgets/batches/wizard_transport_step.dart';

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
  List<Map<String, dynamic>> _purchases = [];
  String _transportPaidBy = 'purchaser';

  // Step 2
  final Map<int, List<Map<String, dynamic>>> _partnersByGroup = {};
  final Map<int, String?> _sellerByGroup = {};

  // Step 3
  final Map<int, List<Map<String, dynamic>>> _packingByGroup = {};

  // Step 4
  final Map<int, List<Map<String, dynamic>>> _expensesByGroup = {};

  // Step 5
  final Map<int, List<Map<String, dynamic>>> _loadsByGroup = {};

  int _activeGroup = 1;

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
        context.read<SupplierProvider>().loadSuppliers(businessId);
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
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
            _purchases.isNotEmpty &&
            _purchases.every(
              (p) =>
                  (p['supplierName'] as String? ?? '').trim().isNotEmpty &&
                  ((p['quantity'] as num?)?.toDouble() ?? 0) > 0 &&
                  ((p['pricePerUnit'] as num?)?.toDouble() ?? 0) > 0,
            );
      case 1:
        final usedGroups = [
          for (var g = 1; g <= _groupCount; g++)
            if (_purchasesFor(g).isNotEmpty) g,
        ];
        return usedGroups.every(
          (g) =>
              _partnersFor(g).isNotEmpty &&
              _partnersFor(g).first['partner_id'] != null &&
              _sellerFor(g) != null,
        );
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

  int get _groupCount {
    var max = 1;
    for (final p in _purchases) {
      final g = (p['batchGroup'] as int?) ?? 1;
      if (g > max) max = g;
    }
    return max;
  }

  List<Map<String, dynamic>> _purchasesFor(int g) =>
      _purchases.where((p) => ((p['batchGroup'] as int?) ?? 1) == g).toList();

  double _groupQuantityKg(int g) => _purchasesFor(g).fold<double>(
    0,
    (acc, p) => acc + (((p['kgTotal'] as num?)?.toDouble() ?? 0)),
  );

  double _groupPurchaseCost(int g) => _purchasesFor(g).fold<double>(
    0,
    (acc, p) => acc + (((p['lineCost'] as num?)?.toDouble() ?? 0)),
  );

  double _groupPaidAmount(int g) => _purchasesFor(g).fold<double>(
    0,
    (acc, p) => acc + (((p['amountPaid'] as num?)?.toDouble() ?? 0)),
  );

  List<String> _groupSuppliers(int g) => _purchasesFor(g)
      .map((p) => (p['supplierName'] as String? ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  List<String> _mergedSuppliers(BuildContext context) {
    final names = <String>{
      ...context.watch<SupplierProvider>().suppliers,
      for (final p in _purchases)
        if (((p['supplierName'] as String?) ?? '').trim().isNotEmpty)
          (p['supplierName'] as String).trim(),
    };
    return names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  String _groupPaymentMode(int g) {
    final modes = _purchasesFor(g)
        .map((p) => (p['paymentMode'] as String? ?? 'cash'))
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    if (modes.length == 1) return modes.first;
    return modes.isEmpty ? 'cash' : 'part_credit';
  }

  List<Map<String, dynamic>> _partnersFor(int g) =>
      _partnersByGroup[g] ?? const [];

  String? _sellerFor(int g) => _sellerByGroup[g];

  List<Map<String, dynamic>> _packingFor(int g) =>
      _packingByGroup[g] ?? const [];

  List<Map<String, dynamic>> _expensesFor(int g) =>
      _expensesByGroup[g] ?? const [];

  List<Map<String, dynamic>> _loadsFor(int g) => _loadsByGroup[g] ?? const [];

  double _groupPackingCost(int g) => _packingFor(g).fold<double>(0, (acc, p) {
    final count = (p['unit_count'] as int?) ?? 0;
    final cost = (p['cost_per_unit'] as num?)?.toDouble() ?? 0;
    return acc + count * cost;
  });

  double _groupExpenseCost(int g) => _expensesFor(
    g,
  ).fold<double>(0, (acc, e) => acc + ((e['amount'] as num?)?.toDouble() ?? 0));

  double _groupDailyCharges(int g) => _partnersFor(g).fold<double>(0, (acc, p) {
    final rate = (p['daily_charge_rate'] as num?)?.toDouble() ?? 0;
    final days = (p['days_involved'] as int?) ?? 1;
    return acc + rate * days;
  });

  double _groupLoadCost(int g) =>
      _loadsFor(g).fold<double>(0, (acc, v) => acc + _loadTotal(v));

  double _loadTotal(Map<String, dynamic> load) {
    final cost = double.tryParse(load['transport_cost'].toString()) ?? 0;
    final units = double.tryParse(load['unit_count'].toString()) ?? 0;
    return load['cost_type'] == 'per_packing' ? units * cost : cost;
  }

  void _addExpense() {
    final g = _activeGroup;
    setState(
      () => _expensesByGroup[g] = [
        ..._expensesFor(g),
        <String, dynamic>{
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
        },
      ],
    );
  }

  Future<void> _submit() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    final groups = [for (var g = 1; g <= _groupCount; g++) g];
    final createdCodes = <String>[];
    setState(() => _submitting = true);
    try {
      for (final g in groups) {
        final lines = _purchasesFor(
          g,
        ).where((p) => ((p['kgTotal'] as num?)?.toDouble() ?? 0) > 0).toList();
        if (lines.isEmpty) continue;
        final totalQty = lines.fold<double>(
          0,
          (acc, p) => acc + ((p['kgTotal'] as num?)?.toDouble() ?? 0),
        );
        final totalCost = lines.fold<double>(
          0,
          (acc, p) => acc + ((p['lineCost'] as num?)?.toDouble() ?? 0),
        );
        final paidAmount = lines.fold<double>(
          0,
          (acc, p) => acc + ((p['amountPaid'] as num?)?.toDouble() ?? 0),
        );
        final suppliers = lines
            .map((p) => (p['supplierName'] as String? ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        final paymentModes = lines
            .map((p) => (p['paymentMode'] as String? ?? 'cash'))
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList();
        final aggregatePaymentMode = paymentModes.length == 1
            ? paymentModes.first
            : (paymentModes.isEmpty ? 'cash' : 'part_credit');

        final batchCode = _generateBatchCode();
        final payload = BatchCreateRequest(
          businessId: businessId,
          productId: _productId!,
          sourceMarketId: _sourceMarketId,
          destinationMarketId: _destinationMarketId,
          batchCode: batchCode,
          purchaseDate: _purchaseDate.toIso8601String().split('T').first,
          totalQuantity: totalQty,
          quantityUnit: 'kg',
          purchasePricePerUnit: totalQty > 0 ? totalCost / totalQty : 0,
          transportPaidBy: _transportPaidBy,
          supplierName: suppliers.isEmpty ? null : suppliers.join(', '),
          purchasePaymentMode: aggregatePaymentMode,
          purchaseAmountPaid: paidAmount,
          purchases: lines
              .map(
                (p) => BatchPurchaseCreate(
                  marketId: p['marketId'] as String?,
                  supplierName: (p['supplierName'] as String? ?? '').trim(),
                  unitLabel: p['unitLabel'] as String? ?? 'kg',
                  unitKg: ((p['unitKg'] as num?)?.toDouble() ?? 1),
                  quantity: ((p['quantity'] as num?)?.toDouble() ?? 0),
                  pricePerUnit: ((p['pricePerUnit'] as num?)?.toDouble() ?? 0),
                  paymentMode: p['paymentMode'] as String?,
                  amountPaid: ((p['amountPaid'] as num?)?.toDouble() ?? 0),
                ),
              )
              .toList(),
          partners: [
            ..._partnersFor(g)
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
            if (_sellerFor(g) != null)
              BatchPartnerCreate(
                partnerId: _sellerFor(g)!,
                role: 'seller',
                dailyChargeRate: 0,
                daysInvolved: 1,
              ),
          ],
          packingRecords: _packingFor(g)
              .where(
                (p) =>
                    ((p['unit_count'] as num?)?.toInt() ?? 0) > 0 ||
                    ((p['packed_kg'] as num?)?.toDouble() ?? 0) > 0,
              )
              .map(
                (p) {
                  final isCustom = p['unit_type'] == 'custom';
                  final count = (p['unit_count'] as num?)?.toInt() ?? 0;
                  return PackingRecordCreate(
                    unitType: p['unit_type'] as String,
                    unitLabel: p['unit_label'] as String?,
                    unitCount: isCustom && count <= 0 ? 1 : count,
                    costPerUnit:
                        (p['cost_per_unit'] as num?)?.toDouble() ?? 0,
                  );
                },
              )
              .toList(),
          expenses: _expensesFor(g)
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
          vehicleLoads: _loadsFor(g)
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

        final ok = await context.read<BatchListProvider>().create(payload);
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create batch $g: ${context.read<BatchListProvider>().error ?? 'Unknown error'}',
              ),
              duration: const Duration(seconds: 6),
            ),
          );
          return;
        }
        createdCodes.add(batchCode);
        try {
          await _createTransportDebt(businessId, batchCode, g);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Transport debt skipped for batch $batchCode: $e');
          }
        }
        if (!mounted) return;
      }

      DataRefreshNotifier.instance.refresh(businessId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdCodes.length == groups.length
                ? (groups.length > 1
                      ? 'Created ${groups.length} batches'
                      : 'Batch created')
                : 'Created ${createdCodes.length} of ${groups.length} batches — check the wizard for details',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createTransportDebt(
    String businessId,
    String batchCode,
    int group,
  ) async {
    if (_transportPaidBy != 'seller') return;
    final sellerId = _sellerFor(group);
    if (sellerId == null) return;
    final purchaserId =
        _partnersFor(group).firstWhere(
              (p) => p['partner_id'] != null,
              orElse: () => {},
            )['partner_id']
            as String?;
    if (purchaserId == null) return;
    if (purchaserId == sellerId) return;
    final transportTotal = _expensesFor(group).fold<double>(
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
        toPartnerId: sellerId,
        amount: transportTotal,
        transactionType: 'transport_debt',
        transactionDate: DateTime.now().toIso8601String().split('T').first,
        notes: 'Auto: seller paid transport for $batchCode',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wizard = context.watch<BatchWizardProvider>();
    final currentStep = wizard.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Produce Batch',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(HeroIcons.x_mark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _stepperBar(theme, currentStep),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                WizardBasicInfoStep(
                  productId: _productId,
                  productName: _productName,
                  sourceMarketId: _sourceMarketId,
                  destinationMarketId: _destinationMarketId,
                  purchaseDate: _purchaseDate,
                  purchases: _purchases,
                  transportPaidBy: _transportPaidBy,
                  suppliers: _mergedSuppliers(context),
                  onProductChanged: (id, name) => setState(() {
                    _productId = id;
                    _productName = name;
                  }),
                  onSourceMarketChanged: (v) =>
                      setState(() => _sourceMarketId = v),
                  onDestinationMarketChanged: (v) =>
                      setState(() => _destinationMarketId = v),
                  onPurchaseDateChanged: (d) =>
                      setState(() => _purchaseDate = d),
                  onPurchasesChanged: (entries) =>
                      setState(() => _purchases = entries),
                  onTransportPaidByChanged: (v) =>
                      setState(() => _transportPaidBy = v),
                  onCreateSupplier: (name) async {
                    final auth = context.read<AuthProvider>();
                    final id = auth.businessId;
                    if (id == null || id.isEmpty) return;
                    final suppliers = context.read<SupplierProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final theme = Theme.of(context);
                    final err = await suppliers.createSupplier(id, name);
                    if (err != null && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Could not save supplier: $err'),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  },
                ),
                WizardPartnersStep(
                  groupCount: _groupCount,
                  activeGroup: _activeGroup,
                  onGroupSelected: (g) => setState(() => _activeGroup = g),
                  businessId: context.read<AuthProvider>().businessId ?? '',
                  partnersForActiveGroup: _partnersFor(_activeGroup),
                  sellerForActiveGroup: _sellerFor(_activeGroup),
                  onPartnersChanged: (selected) =>
                      setState(() => _partnersByGroup[_activeGroup] = selected),
                  onSellerChanged: (v) =>
                      setState(() => _sellerByGroup[_activeGroup] = v),
                ),
                WizardPackingStep(
                  groupCount: _groupCount,
                  activeGroup: _activeGroup,
                  onGroupSelected: (g) => setState(() => _activeGroup = g),
                  packingForActiveGroup: _packingFor(_activeGroup),
                  groupQuantityKg: _groupQuantityKg(_activeGroup),
                  onPackingChanged: (records) =>
                      setState(() => _packingByGroup[_activeGroup] = records),
                ),
                WizardExpensesStep(
                  groupCount: _groupCount,
                  activeGroup: _activeGroup,
                  onGroupSelected: (g) => setState(() => _activeGroup = g),
                  expensesForActiveGroup: _expensesFor(_activeGroup),
                  onExpensesChanged: (expenses) =>
                      setState(() => _expensesByGroup[_activeGroup] = expenses),
                  onAddExpense: _addExpense,
                ),
                WizardTransportStep(
                  groupCount: _groupCount,
                  activeGroup: _activeGroup,
                  onGroupSelected: (g) => setState(() => _activeGroup = g),
                  loadsForActiveGroup: _loadsFor(_activeGroup),
                  packingForActiveGroup: _packingFor(_activeGroup),
                  onLoadsChanged: (loads) =>
                      setState(() => _loadsByGroup[_activeGroup] = loads),
                ),
                WizardReviewStep(
                  groupCount: _groupCount,
                  productName: _productName,
                  purchasesForGroup: _purchasesFor,
                  groupQuantityKg: _groupQuantityKg,
                  groupPurchaseCost: _groupPurchaseCost,
                  groupPaidAmount: _groupPaidAmount,
                  groupSuppliers: _groupSuppliers,
                  groupPaymentMode: _groupPaymentMode,
                  groupPackingCost: _groupPackingCost,
                  groupExpenseCost: _groupExpenseCost,
                  groupDailyCharges: _groupDailyCharges,
                  groupLoadCost: _groupLoadCost,
                  loadsForGroup: _loadsFor,
                  partnersForGroup: _partnersFor,
                ),
              ],
            ),
          ),
          _navBar(theme, currentStep),
        ],
      ),
    );
  }

  Widget _stepperBar(ThemeData theme, int currentStep) {
    const labels = [
      'Basic',
      'Partners',
      'Packing',
      'Expenses',
      'Transport',
      'Review',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.primary
                    : AppColors.divider,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isActive = stepIndex == currentStep;
          final isDone = stepIndex < currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone
                    ? AppColors.primary
                    : isActive
                        ? AppColors.primarySurface
                        : AppColors.surfaceAlt,
                child: isDone
                    ? const Icon(
                        HeroIcons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIndex],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _navBar(ThemeData theme, int currentStep) {
    final isLast = currentStep == 5;
    final canNext = _validateStep(currentStep);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStep > 0) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _prev,
                  child: Text(
                    'Back',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: currentStep > 0 ? 2 : 1,
              child: isLast
                  ? FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create Batch',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                            ),
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: canNext ? _next : null,
                      child: Text(
                        'Continue to Next Step',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
