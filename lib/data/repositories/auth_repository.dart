import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../datasources/remote/auth_remote_ds.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authRemoteDsProvider));
});

class AuthRepository {
  final AuthRemoteDs _remoteDs;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._remoteDs);

  Future<UserModel> login(String email, String password) async {
    final response = await _remoteDs.login(email, password);
    final data = response['data'] as Map<String, dynamic>;
    await _storage.write(key: 'access_token', value: data['access_token'] as String);
    await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
    return UserModel.fromJson(data);
  }

  Future<UserModel> signup(Map<String, dynamic> data) async {
    final response = await _remoteDs.signup(data);
    final userData = response['data'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }
}
