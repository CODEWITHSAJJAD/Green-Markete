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

  double _outstandingCredit = 0;
  double get outstandingCredit => _outstandingCredit;

  int _activeBatchesCount = 0;
  int get activeBatchesCount => _activeBatchesCount;

  int _batchesCount = 0;
  int get batchesCount => _batchesCount;

  int _productsCount = 0;
  int get productsCount => _productsCount;

  int _customersCount = 0;
  int get customersCount => _customersCount;

  List<BatchModel> _recentBatches = const [];
  List<BatchModel> get recentBatches => _recentBatches;

  Future<void> load(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final summary = await _repo.getSummary(businessId);
      _todaySales = summary.todaySales;
      _outstandingCredit = summary.outstandingCredit;
      _activeBatchesCount = summary.activeBatches;
      _batchesCount = summary.totalBatches;
      _productsCount = summary.totalProducts;
      _customersCount = summary.totalCustomers;
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
