import 'package:flutter/foundation.dart';

import '../../data/models/customer_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._repo);

  final CustomerRepository _repo;

  List<CustomerModel> _customers = const [];
  List<CustomerModel> get customers => _customers;

  List<CustomerLedgerEntry> _ledger = const [];
  List<CustomerLedgerEntry> get ledger => _ledger;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId, {String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _repo.list(businessId, search: search);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerModel?> create(Map<String, dynamic> data) async {
    try {
      final customer = await _repo.create(data);
      return customer;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> loadLedger(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _ledger = await _repo.getLedger(customerId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordPayment(String customerId, PaymentCreateRequest payment) async {
    try {
      await _repo.recordPayment(customerId, payment);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
