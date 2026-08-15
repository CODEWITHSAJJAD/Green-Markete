import 'package:flutter/foundation.dart';

import '../../data/models/batch_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repo);

  final DashboardRepository _repo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  double _todaySales = 0;
  double get todaySales => _todaySales;

  int _todaySalesCount = 0;
  int get todaySalesCount => _todaySalesCount;

  double _totalRevenue = 0;
  double get totalRevenue => _totalRevenue;

  double _totalCost = 0;
  double get totalCost => _totalCost;

  double _totalProfitLoss = 0;
  double get totalProfitLoss => _totalProfitLoss;

  double _outstandingCredit = 0;
  double get outstandingCredit => _outstandingCredit;

  double _supplierPayables = 0;
  double get supplierPayables => _supplierPayables;

  int _activeBatchesCount = 0;
  int get activeBatchesCount => _activeBatchesCount;

  int _sellingBatchesCount = 0;
  int get sellingBatchesCount => _sellingBatchesCount;

  int _batchesCount = 0;
  int get batchesCount => _batchesCount;

  int _productsCount = 0;
  int get productsCount => _productsCount;

  int _customersCount = 0;
  int get customersCount => _customersCount;

  int _customersWithCreditCount = 0;
  int get customersWithCreditCount => _customersWithCreditCount;

  List<BatchModel> _recentBatches = const [];
  List<BatchModel> get recentBatches => _recentBatches;

  Future<void> load(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      final summary = await _repo.getSummary(businessId);
      _todaySales = summary.todaySales;
      _todaySalesCount = summary.todaySalesCount;
      _totalRevenue = summary.totalRevenue;
      _totalCost = summary.totalCost;
      _totalProfitLoss = summary.totalProfitLoss;
      _outstandingCredit = summary.outstandingCredit;
      _supplierPayables = summary.supplierPayables;
      _activeBatchesCount = summary.activeBatches;
      _sellingBatchesCount = summary.sellingBatches;
      _batchesCount = summary.totalBatches;
      _productsCount = summary.totalProducts;
      _customersCount = summary.totalCustomers;
      _customersWithCreditCount = summary.customersWithCreditCount;
      _recentBatches = summary.recentBatches;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}