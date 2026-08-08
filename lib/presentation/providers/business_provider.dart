import 'package:flutter/foundation.dart';

import '../../data/models/business_model.dart';
import '../../data/repositories/business_repository.dart';

class BusinessProvider extends ChangeNotifier {
  BusinessProvider(this._repo);

  final BusinessRepository _repo;

  BusinessModel? _business;
  BusinessModel? get business => _business;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _business = await _repo.fetch(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings({
    String? name,
    double? creditAlertThreshold,
  }) async {
    final businessId = _business?.id;
    if (businessId == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.updateSettings(
        businessId,
        name: name,
        creditAlertThreshold: creditAlertThreshold,
      );
      _business = BusinessModel(
        id: businessId,
        name: name ?? _business!.name,
        ownerId: _business!.ownerId,
        businessType: _business!.businessType,
        creditAlertThreshold:
            creditAlertThreshold ?? _business!.creditAlertThreshold,
        createdAt: _business!.createdAt,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<BusinessModel?> create({
    required String name,
    String? city,
    String businessType = 'multi_partner',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final business = await _repo.create(
        name: name,
        city: city,
        businessType: businessType,
      );
      _business = business;
      _isLoading = false;
      notifyListeners();
      return business;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clear() {
    _business = null;
    _error = null;
  }
}
