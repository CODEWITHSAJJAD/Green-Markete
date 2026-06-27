import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/batch_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/sale_repository.dart';

final batchListProvider = FutureProvider.family<List<BatchModel>, String>((ref, businessId) async {
  final repo = ref.watch(batchRepositoryProvider);
  final result = await repo.list(businessId: businessId);
  final data = result['data'] as Map<String, dynamic>?;
  final items = data?['items'] as List<dynamic>? ?? [];
  return items.map((e) => BatchModel.fromJson(e as Map<String, dynamic>)).toList();
});

final batchDetailProvider = FutureProvider.family<BatchModel, String>((ref, id) async {
  final repo = ref.watch(batchRepositoryProvider);
  return repo.get(id);
});

final batchPLProvider = FutureProvider.family<BatchPLSummaryModel, String>((ref, id) async {
  final repo = ref.watch(batchRepositoryProvider);
  return repo.getSummary(id);
});

final batchExpensesProvider = FutureProvider.family<List, String>((ref, batchId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.list(batchId);
});

final batchSalesProvider = FutureProvider.family<List, String>((ref, batchId) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.listByBatch(batchId);
});

class BatchWizardState {
  final int currentStep;
  final String? productId;
  final String? sourceMarketId;
  final String? destinationMarketId;
  final String? purchaseDate;
  final double? totalQuantity;
  final String? quantityUnit;
  final double? purchasePricePerUnit;
  final String? transportPaidBy;
  final List<Map<String, dynamic>> partners;
  final List<Map<String, dynamic>> packingRecords;
  final List<Map<String, dynamic>> expenses;

  const BatchWizardState({
    this.currentStep = 0,
    this.productId,
    this.sourceMarketId,
    this.destinationMarketId,
    this.purchaseDate,
    this.totalQuantity,
    this.quantityUnit,
    this.purchasePricePerUnit,
    this.transportPaidBy,
    this.partners = const [],
    this.packingRecords = const [],
    this.expenses = const [],
  });

  BatchWizardState copyWith({
    int? currentStep,
    String? productId,
    String? sourceMarketId,
    String? destinationMarketId,
    String? purchaseDate,
    double? totalQuantity,
    String? quantityUnit,
    double? purchasePricePerUnit,
    String? transportPaidBy,
    List<Map<String, dynamic>>? partners,
    List<Map<String, dynamic>>? packingRecords,
    List<Map<String, dynamic>>? expenses,
  }) {
    return BatchWizardState(
      currentStep: currentStep ?? this.currentStep,
      productId: productId ?? this.productId,
      sourceMarketId: sourceMarketId ?? this.sourceMarketId,
      destinationMarketId: destinationMarketId ?? this.destinationMarketId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      purchasePricePerUnit: purchasePricePerUnit ?? this.purchasePricePerUnit,
      transportPaidBy: transportPaidBy ?? this.transportPaidBy,
      partners: partners ?? this.partners,
      packingRecords: packingRecords ?? this.packingRecords,
      expenses: expenses ?? this.expenses,
    );
  }
}

class BatchWizardNotifier extends StateNotifier<BatchWizardState> {
  BatchWizardNotifier() : super(const BatchWizardState());

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void updateProduct(String productId) {
    state = state.copyWith(productId: productId);
  }

  void updateMarkets(String? source, String? destination) {
    state = state.copyWith(
      sourceMarketId: source,
      destinationMarketId: destination,
    );
  }

  void updatePurchaseDetails({
    String? date,
    double? quantity,
    String? unit,
    double? price,
    String? transportPaidBy,
  }) {
    state = state.copyWith(
      purchaseDate: date,
      totalQuantity: quantity,
      quantityUnit: unit,
      purchasePricePerUnit: price,
      transportPaidBy: transportPaidBy,
    );
  }

  void updatePartners(List<Map<String, dynamic>> partners) {
    state = state.copyWith(partners: partners);
  }

  void updatePackingRecords(List<Map<String, dynamic>> records) {
    state = state.copyWith(packingRecords: records);
  }

  void updateExpenses(List<Map<String, dynamic>> expenses) {
    state = state.copyWith(expenses: expenses);
  }

  void reset() {
    state = const BatchWizardState();
  }
}

final batchWizardProvider = StateNotifierProvider<BatchWizardNotifier, BatchWizardState>((ref) {
  return BatchWizardNotifier();
});
