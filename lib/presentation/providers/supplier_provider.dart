import 'package:flutter/foundation.dart';

import '../../data/models/supplier_payment_model.dart';
import '../../data/repositories/batch_repository.dart';

class SupplierProvider extends ChangeNotifier {
  SupplierProvider(this._repo);

  final BatchRepository _repo;

  List<SupplierOutstanding> _outstanding = const [];
  List<SupplierOutstanding> get outstanding => _outstanding;

  List<SupplierLedgerEntry> _ledger = const [];
  List<SupplierLedgerEntry> get ledger => _ledger;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadOutstanding(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _outstanding = await _repo.getSupplierOutstanding(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLedger(String businessId, String supplierName) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _ledger =
          await _repo.getSupplierLedger(businessId, supplierName);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordPayment(SupplierPaymentCreateRequest request) async {
    try {
      await _repo.recordSupplierPayment(request);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}