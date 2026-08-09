import 'package:flutter/foundation.dart';

import '../../core/utils/currency_formatter.dart';
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
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _business = await _repo.fetch(businessId);
      if (_business != null) {
        CurrencyFormatter.currentCode = _business!.currencyCode;
      }
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
    String? currencyCode,
  }) async {
    final businessId = _business?.id;
    if (businessId == null) return false;
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      await _repo.updateSettings(
        businessId,
        name: name,
        creditAlertThreshold: creditAlertThreshold,
        currencyCode: currencyCode,
      );
      _business = BusinessModel(
        id: businessId,
        name: name ?? _business!.name,
        ownerId: _business!.ownerId,
        businessType: _business!.businessType,
        creditAlertThreshold:
            creditAlertThreshold ?? _business!.creditAlertThreshold,
        currencyCode: currencyCode ?? _business!.currencyCode,
        createdAt: _business!.createdAt,
      );
      CurrencyFormatter.currentCode = _business!.currencyCode;
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
    await Future<void>.value();
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