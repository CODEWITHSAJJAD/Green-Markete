import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/business_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  String? get currentUserPhone => _client.auth.currentUser?.phone;

  String? get currentUserEmail => _client.auth.currentUser?.email;

  Stream<AuthState> get onAuthStateChanged => _client.auth.onAuthStateChange;

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);
    final userId = response.user?.id;
    if (userId == null) {
      throw Exception('Sign up failed. Please try again.');
    }
    return UserModel.fromJson({'user_id': userId, 'email': email});
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> resendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone, channel: OtpChannel.sms);
  }

  Future<void> verifyPhoneOtp(String phone, String token) async {
    await _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> fetchUserProfile(String userId) async {
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserModel.fromJson(row);
  }

  Future<UserModel> createUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? email,
    String? city,
  }) async {
    final row = await _client
        .from('user_profiles')
        .insert({
          'user_id': userId,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          if (city != null && city.isNotEmpty) 'city': city,
        })
        .select()
        .single();
    return UserModel.fromJson(row);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('user_profiles').update(data).eq('user_id', userId);
  }

  Future<String?> getMyBusinessId(String userId) async {
    final row = await _client
        .from('business_partners')
        .select('business_id')
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .maybeSingle();
    return row?['business_id'] as String?;
  }

  Future<BusinessModel?> getMyBusiness(String businessId) async {
    final row = await _client
        .from('businesses')
        .select()
        .eq('id', businessId)
        .maybeSingle();
    if (row == null) return null;
    return BusinessModel.fromJson(row);
  }

  Future<void> claimBusinessByPhone({required String userId, required String phone}) async {
    final match = await _client
        .from('business_partners')
        .select('id, business_id')
        .eq('phone', phone)
        .isFilter('user_id', null)
        .maybeSingle();
    if (match == null) return;
    await _client
        .from('business_partners')
        .update({'user_id': userId, 'is_claimed': true})
        .eq('id', match['id'] as String);
  }
}
