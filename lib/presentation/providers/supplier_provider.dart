import 'package:flutter/foundation.dart';

import '../../data/models/supplier_payment_model.dart';
import '../../data/repositories/batch_repository.dart';

class SupplierProvider extends ChangeNotifier {
  SupplierProvider(this._repo);

  final BatchRepository _repo;

  List<String> _suppliers = const [];
  List<String> get suppliers => _suppliers;

  List<SupplierOutstanding> _outstanding = const [];
  List<SupplierOutstanding> get outstanding => _outstanding;

  List<SupplierLedgerEntry> _ledger = const [];
  List<SupplierLedgerEntry> get ledger => _ledger;

  List<SupplierBatchSummary> _batchSummaries = const [];
  List<SupplierBatchSummary> get batchSummaries => _batchSummaries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadSuppliers(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _suppliers = await _repo.getDistinctSupplierNames(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a newly-created supplier name to the registry and refreshes the
  /// suggestion list so it is immediately available in future sessions.
  /// Returns a human-readable error message on failure, or null on success.
  Future<String?> createSupplier(String businessId, String name) async {
    try {
      await _repo.createSupplier(businessId, name);
      await loadSuppliers(businessId);
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _error = msg;
      notifyListeners();
      return msg;
    }
  }

  Future<void> loadOutstanding(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _outstanding = await _repo.getSupplierOutstanding(
        businessId,
        from: from,
        to: to,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBatchSummaries(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      _batchSummaries = await _repo.getSupplierBatchSummaries(
        businessId,
        from: from,
        to: to,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadLedger(
    String businessId,
    String supplierName, {
    DateTime? from,
    DateTime? to,
  }) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _ledger = await _repo.getSupplierLedger(
        businessId,
        supplierName,
        from: from,
        to: to,
      );
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
