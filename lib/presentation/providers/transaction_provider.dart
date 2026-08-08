import 'package:flutter/foundation.dart';

import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._repo);

  final TransactionRepository _repo;

  Map<String, dynamic>? _ledger;
  Map<String, dynamic>? get ledger => _ledger;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadLedger(String partnerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _ledger = await _repo.getPartnerLedger(partnerId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel?> create(TransactionCreateRequest request) async {
    try {
      return await _repo.create(request);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
