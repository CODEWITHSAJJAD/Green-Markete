import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final authRemoteDsProvider = Provider<AuthRemoteDs>((ref) {
  return AuthRemoteDs(ref.watch(dioProvider));
});

class AuthRemoteDs {
  final Dio _dio;
  AuthRemoteDs(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/signup', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/auth/refresh-token', data: {
      'refresh_token': refreshToken,
    });
    return response.data as Map<String, dynamic>;
  }
}
