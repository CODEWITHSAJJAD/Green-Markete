import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/business_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'capability.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    Future.microtask(restoreSession);
  }

  final AuthRepository _repo;

  UserModel? _user;
  UserModel? get user => _user;

  bool get isAuthenticated => _user != null;

  bool _needsOnboarding = false;
  bool get needsOnboarding => _needsOnboarding;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? get userId => _repo.currentUserId;
  String? get businessId => _user?.businessId;

  List<BusinessModel> _businesses = [];
  List<BusinessModel> get businesses => _businesses;

  List<MembershipModel> _memberships = [];
  List<MembershipModel> get memberships => _memberships;

  String? _accessLevel;
  String get accessLevel => _accessLevel ?? '';

  String? _sideRole;
  String get sideRole => _sideRole ?? '';

  bool _manageOtherSide = false;
  bool get manageOtherSide => _manageOtherSide;

  static const _lastBusinessKey = 'gm_last_active_business';

  CapabilityService get capabilities =>
      CapabilityService(_accessLevel ?? '', sideRole: _sideRole ?? 'both', manageOtherSide: _manageOtherSide);

  bool canEditSide(String side) => capabilities.canEditSide(side);
  bool get canEditPurchaserSide => capabilities.canEditPurchaserSide;
  bool get canEditSellerSide => capabilities.canEditSellerSide;

  String? _businessNameFor(String businessId) {
    for (final b in _businesses) {
      if (b.id == businessId) return b.name;
    }
    return null;
  }

  String describeMembership(MembershipModel m) {
    final name = _businessNameFor(m.businessId) ?? 'Business';
    final role = m.isOwner
        ? 'Owner'
        : m.role == 'accountant'
            ? 'Accountant'
            : '${describeAccess(m.accessLevel)} · ${describeSide(m.sideRole)}';
    return '$name — $role';
  }

  Future<void> loadBusinesses() async {
    final uid = _repo.currentUserId;
    if (uid == null) return;
    try {
      _memberships = await _repo.listMyMemberships(uid);
      _businesses = await _repo.listMyBusinesses(uid);
      final active = businessId;
      if (active != null && !_memberships.any((m) => m.businessId == active)) {
        _activateBusiness(
          _memberships.isNotEmpty ? _memberships.first.businessId : null,
        );
      }
      notifyListeners();
    } catch (_) {
      _businesses = [];
      _memberships = [];
      notifyListeners();
    }
  }

  Future<void> switchBusiness(String businessId) async {
    final current = _user;
    if (current == null) return;
    _activateBusiness(businessId);
    notifyListeners();
  }

  void _activateBusiness(String? businessId) {
    final current = _user;
    if (current == null) return;
    if (businessId == null) {
      _user = UserModel(
        id: current.id,
        fullName: current.fullName,
        phone: current.phone,
        email: current.email,
        city: current.city,
        role: 'viewer',
        businessId: null,
        isActive: current.isActive,
      );
      _accessLevel = null;
      _sideRole = null;
      _manageOtherSide = false;
      _needsOnboarding = true;
      return;
    }
    final membership = _memberships.where((m) => m.businessId == businessId).firstOrNull;
    final isOwnerOf = _businesses.any((b) => b.id == businessId && b.ownerId == current.id);
    String role;
    if (isOwnerOf) {
      role = 'owner';
      _accessLevel = 'owner';
      _sideRole = 'both';
      _manageOtherSide = true;
    } else if (membership != null) {
      role = membership.effectiveAccessRole;
      _accessLevel = membership.accessLevel;
      _sideRole = membership.sideRole;
      _manageOtherSide = false;
    } else {
      role = current.role ?? 'viewer';
      _accessLevel = current.role;
      _sideRole = 'both';
      _manageOtherSide = false;
    }
    _user = UserModel(
      id: current.id,
      fullName: current.fullName,
      phone: current.phone,
      email: current.email,
      city: current.city,
      role: role,
      businessId: businessId,
      isActive: current.isActive,
    );
    _needsOnboarding = false;
    SharedPreferences.getInstance().then(
      (p) => p.setString(_lastBusinessKey, businessId),
    );
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      final userId = _repo.currentUserId;
      if (userId == null) {
        _user = null;
        _memberships = [];
        _businesses = [];
        _needsOnboarding = false;
        _isLoading = false;
        notifyListeners();
        return;
      }
      var profile = await _repo.fetchUserProfile(userId);
      if (profile == null && _repo.currentUserPhone != null) {
        profile = await _repo.createUserProfile(
          userId: userId,
          phone: _repo.currentUserPhone,
        );
      }
      _memberships = await _repo.listMyMemberships(userId);
      _businesses = await _repo.listMyBusinesses(userId);
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_lastBusinessKey);
      String? businessId;
      if (saved != null && _memberships.any((m) => m.businessId == saved)) {
        businessId = saved;
      } else if (_memberships.isNotEmpty) {
        businessId = _memberships.first.businessId;
      }
      final membership = businessId == null
          ? null
          : _memberships.where((m) => m.businessId == businessId).firstOrNull;
      var role = membership?.effectiveAccessRole;
      if (role == null || role.isEmpty) role = profile?.role;
      _accessLevel = membership?.accessLevel;
      _sideRole = membership?.sideRole;
      _manageOtherSide = false;
      _user = UserModel(
        id: userId,
        fullName: profile?.fullName,
        phone: profile?.phone ?? _repo.currentUserPhone,
        email: profile?.email ?? _repo.currentUserEmail,
        city: profile?.city,
        role: role ?? 'viewer',
        businessId: businessId,
        isActive: profile?.isActive ?? true,
      );
      _needsOnboarding = _memberships.isEmpty;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      await _repo.signInWithEmail(email: email, password: password);
      await restoreSession();
      return isAuthenticated;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? city,
  }) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      final user = await _repo.signUpWithEmail(email: email, password: password);
      await _repo.createUserProfile(
        userId: user.id,
        fullName: fullName,
        phone: phone,
        email: email,
        city: city,
      );
      await restoreSession();
      return isAuthenticated;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      await _repo.sendPhoneOtp(phone);
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

  Future<bool> verifyOtp(String phone, String token) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      await _repo.verifyPhoneOtp(phone, token);
      await _repo.claimBusinessByPhone(
        userId: _repo.currentUserId ?? '',
        phone: phone,
      );
      await restoreSession();
      return isAuthenticated;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> completeOnboarding({
    required String fullName,
    String? city,
    String? phone,
  }) async {
    final userId = _repo.currentUserId;
    if (userId == null) return;
    await _repo.createUserProfile(
      userId: userId,
      fullName: fullName,
      phone: phone ?? _repo.currentUserPhone,
      city: city,
    );
    if (phone != null && phone.isNotEmpty) {
      await _repo.claimBusinessByPhone(userId: userId, phone: phone);
    }
    await restoreSession();
  }

  void setBusinessId(String businessId) {
    final current = _user;
    if (current == null) return;
    _activateBusiness(businessId);
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? city,
  }) async {
    final userId = _repo.currentUserId;
    if (userId == null) return false;
    try {
      await _repo.updateUserProfile(userId, {
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        'phone': ?phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'city': ?city,
      });
      final current = _user;
      _user = UserModel(
        id: current?.id ?? userId,
        fullName: fullName ?? current?.fullName,
        phone: phone ?? current?.phone,
        email: email ?? current?.email,
        city: city ?? current?.city,
        role: current?.role,
        businessId: current?.businessId,
        isActive: current?.isActive ?? true,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.signOut();
    } catch (_) {}
    _user = null;
    _memberships = [];
    _businesses = [];
    _accessLevel = null;
    _sideRole = null;
    _manageOtherSide = false;
    _needsOnboarding = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}