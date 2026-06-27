import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/connectivity_service.dart';
import '../../data/datasources/remote/auth_remote_ds.dart';
import '../../data/models/user_model.dart';

class AuthState {
  final bool isAuthenticated;
  final bool needsOnboarding;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.needsOnboarding = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? needsOnboarding,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDs _remoteDs;
  final _storage = const FlutterSecureStorage();
  final ConnectivityService _connectivity;

  AuthNotifier(this._remoteDs, this._connectivity) : super(const AuthState());

  Future<void> checkSession() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _remoteDs.login(email, password);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      final tokens = data['tokens'] as Map<String, dynamic>? ?? data;
      final accessToken = tokens['access_token'] as String? ?? '';
      final refreshToken = tokens['refresh_token'] as String? ?? '';
      if (accessToken.isNotEmpty) {
        await _storage.write(key: 'access_token', value: accessToken);
      }
      if (refreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }
      final user = UserModel.fromJson(userJson);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
        needsOnboarding: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRemoteDsProvider),
    ConnectivityService(),
  );
});
