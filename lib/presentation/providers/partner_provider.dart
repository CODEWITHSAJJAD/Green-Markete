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

  Future<void> load(String businessId, {bool showLoading = true}) async {
    await Future<void>.value();
    if (showLoading && _partners.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;
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
      try {
        _searchResults = await _repo.search(query, businessId);
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
      } finally {
        notifyListeners();
      }
    });
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.remove(id);
      _partners = _partners.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<PartnerModel?> create(Map<String, dynamic> data) async {
    try {
      final partner = await _repo.create(data);
      _partners = [..._partners, partner];
      notifyListeners();
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
      _partners = _partners.map((p) {
        if (p.id == partnerId) {
          return PartnerModel(
            id: p.id,
            fullName: p.fullName,
            phone: p.phone,
            city: p.city,
            role: p.role,
            memberType: p.memberType,
            accessLevel: accessLevel,
            isClaimed: p.isClaimed,
            manageOtherSide: p.manageOtherSide,
            businessId: p.businessId,
            userId: p.userId,
            permissions: p.permissions,
          );
        }
        return p;
      }).toList();
      notifyListeners();
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
      _partners = _partners.map((p) {
        if (p.id == partnerId) {
          return PartnerModel(
            id: p.id,
            fullName: p.fullName,
            phone: p.phone,
            city: p.city,
            role: p.role,
            memberType: p.memberType,
            accessLevel: p.accessLevel,
            isClaimed: p.isClaimed,
            manageOtherSide: value,
            businessId: p.businessId,
            userId: p.userId,
            permissions: p.permissions,
          );
        }
        return p;
      }).toList();
      notifyListeners();
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
      _partners = _partners.map((p) {
        if (p.id == partnerId) {
          return PartnerModel(
            id: p.id,
            fullName: p.fullName,
            phone: p.phone,
            city: p.city,
            role: role,
            memberType: p.memberType,
            accessLevel: p.accessLevel,
            isClaimed: p.isClaimed,
            manageOtherSide: p.manageOtherSide,
            businessId: p.businessId,
            userId: p.userId,
            permissions: p.permissions,
          );
        }
        return p;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMemberType(String partnerId, String memberType, String businessId) async {
    try {
      await _repo.updateMemberType(partnerId, memberType, businessId);
      _partners = _partners.map((p) {
        if (p.id == partnerId) {
          return PartnerModel(
            id: p.id,
            fullName: p.fullName,
            phone: p.phone,
            city: p.city,
            role: p.role,
            memberType: memberType,
            accessLevel: p.accessLevel,
            isClaimed: p.isClaimed,
            manageOtherSide: p.manageOtherSide,
            businessId: p.businessId,
            userId: p.userId,
            permissions: p.permissions,
          );
        }
        return p;
      }).toList();
      notifyListeners();
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
      _partners = _partners.map((p) {
        if (p.id == partnerId) {
          final updatedPerms = Map<String, bool>.from(p.permissions ?? {});
          updatedPerms[permissionKey] = value;
          return PartnerModel(
            id: p.id,
            fullName: p.fullName,
            phone: p.phone,
            city: p.city,
            role: p.role,
            memberType: p.memberType,
            accessLevel: permissionKey == 'can_close_batch'
                ? (value ? 'editor' : 'viewer')
                : p.accessLevel,
            isClaimed: p.isClaimed,
            manageOtherSide: (permissionKey == 'can_purchase' || permissionKey == 'can_sell')
                ? value
                : p.manageOtherSide,
            businessId: p.businessId,
            userId: p.userId,
            permissions: updatedPerms,
          );
        }
        return p;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}