import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

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

  Future<void> restoreSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userId = _repo.currentUserId;
      if (userId == null) {
        _user = null;
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
      final businessId = await _repo.getMyBusinessId(userId);
      final role = profile?.role;
      _user = UserModel(
        id: userId,
        fullName: profile?.fullName,
        phone: profile?.phone ?? _repo.currentUserPhone,
        email: profile?.email ?? _repo.currentUserEmail,
        city: profile?.city,
        role: role,
        businessId: businessId,
        isActive: profile?.isActive ?? true,
      );
      _needsOnboarding = businessId == null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
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
    _user = UserModel(
      id: current.id,
      fullName: current.fullName,
      phone: current.phone,
      email: current.email,
      city: current.city,
      role: current.role,
      businessId: businessId,
      isActive: current.isActive,
    );
    _needsOnboarding = false;
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
    _needsOnboarding = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
