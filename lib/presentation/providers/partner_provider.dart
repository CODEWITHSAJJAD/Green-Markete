import 'package:flutter/foundation.dart';

import '../../core/utils/debouncer.dart';
import '../../data/models/partner_model.dart';
import '../../data/repositories/partner_repository.dart';

class PartnerProvider extends ChangeNotifier {
  PartnerProvider(this._repo);

  final PartnerRepository _repo;
  final Debouncer _debouncer = Debouncer();

  List<PartnerModel> _partners = const [];
  List<PartnerModel> get partners => _partners;

  List<PartnerModel> _searchResults = const [];
  List<PartnerModel> get searchResults => _searchResults;

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
      _partners = await _repo.list(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query, String businessId) {
    if (query.length < 3) {
      _searchResults = const [];
      notifyListeners();
      return;
    }
    _debouncer(() async {
      _isLoading = true;
      await Future<void>.value();
      notifyListeners();
      try {
        _searchResults = await _repo.search(query, businessId);
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<PartnerModel?> create(Map<String, dynamic> data) async {
    try {
      final partner = await _repo.create(data);
      return partner;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAccess(String partnerId, String accessLevel, String businessId) async {
    try {
      await _repo.updateAccess(partnerId, accessLevel, businessId);
      await load(businessId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateManageOtherSide(String partnerId, bool value, String businessId) async {
    try {
      await _repo.updateManageOtherSide(partnerId, value, businessId);
      await load(businessId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRole(String partnerId, String role, String businessId) async {
    try {
      await _repo.updateRole(partnerId, role, businessId);
      await load(businessId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePermission(
    String partnerId,
    String permissionKey,
    bool value,
    String businessId,
  ) async {
    try {
      await _repo.updatePermission(partnerId, permissionKey, value, businessId);
      await load(businessId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}