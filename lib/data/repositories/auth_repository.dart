import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/business_model.dart';
import '../models/membership_model.dart';
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
        .upsert({
          'user_id': userId,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          if (city != null && city.isNotEmpty) 'city': city,
        }, onConflict: 'user_id')
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

  Future<String?> getMyRole(String userId, String businessId) async {
    try {
      final owner = await _client
          .from('businesses')
          .select('owner_id')
          .eq('id', businessId)
          .maybeSingle();
      if (owner != null && owner['owner_id'] == userId) return 'owner';
    } catch (_) {
      // Some deployments lack owner_id; fall back to partner access level.
    }
    try {
      final partner = await _client
          .from('business_partners')
          .select('role, access_level')
          .eq('user_id', userId)
          .eq('business_id', businessId)
          .maybeSingle();
      if (partner == null) return null;
      final accessLevel = partner['access_level'] as String?;
      if (accessLevel == 'editor') return 'editor';
      if (accessLevel == 'viewer') return 'viewer';
      final role = partner['role'] as String?;
      if (role == 'accountant') return 'accountant';
      if (accessLevel == null && role == null) return null;
      return 'viewer';
    } catch (_) {
      return null;
    }
  }

  Future<List<BusinessModel>> listMyBusinesses(String userId) async {
    final rows = await _client
        .from('business_partners')
        .select('business_id')
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    final ids = rows.map((r) => r['business_id'] as String?).whereType<String>().toList();
    if (ids.isEmpty) return const [];
    final businessRows = await _client
        .from('businesses')
        .select()
        .inFilter('id', ids);
    final byId = <String, BusinessModel>{
      for (final r in businessRows) r['id'] as String: BusinessModel.fromJson(r),
    };
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
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
    final matches = await _client
        .from('business_partners')
        .select('id')
        .eq('phone', phone)
        .isFilter('user_id', null);
    if (matches.isEmpty) return;
    final ids = matches
        .map((r) => r['id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return;
    await _client
        .from('business_partners')
        .update({'user_id': userId, 'is_claimed': true})
        .inFilter('id', ids);
  }

  /// All businesses the user belongs to (owner row + claimed partnerships),
  /// each with its own role/access level.
  Future<List<MembershipModel>> listMyMemberships(String userId) async {
    final rows = await _client
        .from('business_partners')
        .select('business_id, role, access_level, is_claimed')
        .eq('user_id', userId);
    return [
      for (final r in rows)
        MembershipModel(
          businessId: r['business_id'] as String? ?? '',
          role: r['role'] as String? ?? 'partner',
          accessLevel: r['access_level'] as String?,
          isClaimed: r['is_claimed'] as bool? ?? true,
        ),
    ];
  }
}
