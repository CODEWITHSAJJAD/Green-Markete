import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/partner_model.dart';

class PartnerRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<PartnerModel>> list(String businessId) async {
    final rows = await _client
        .from('business_partners')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: true);
    final profiles = await _fetchProfiles(rows);
    return rows.map((r) => _mergeProfile(r, profiles)).map(PartnerModel.fromJson).toList();
  }

  Future<List<PartnerModel>> search(String query, String businessId) async {
    final rows = await _client
        .from('business_partners')
        .select()
        .eq('business_id', businessId)
        .or('full_name.ilike.%$query%,phone.ilike.%$query%')
        .order('full_name');
    final profiles = await _fetchProfiles(rows);
    return rows.map((r) => _mergeProfile(r, profiles)).map(PartnerModel.fromJson).toList();
  }

  Future<PartnerModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from('business_partners')
        .insert({
          'business_id': data['business_id'],
          'full_name': data['full_name'],
          'phone': data['phone'],
          'role': data['role'] ?? 'partner',
          'access_level': data['access_level'] ?? 'viewer',
          'manage_other_side': data['manage_other_side'] ?? false,
          'is_claimed': false,
        })
        .select()
        .single();
    return PartnerModel.fromJson(row);
  }

  Future<void> invite(String partnerId) async {
    return;
  }

  Future<void> updateAccess(
    String partnerId,
    String accessLevel,
    String businessId,
  ) async {
    await _client
        .from('business_partners')
        .update({'access_level': accessLevel})
        .eq('id', partnerId)
        .eq('business_id', businessId);
  }

  Future<void> updateManageOtherSide(
    String partnerId,
    bool manageOtherSide,
    String businessId,
  ) async {
    await _client
        .from('business_partners')
        .update({'manage_other_side': manageOtherSide})
        .eq('id', partnerId)
        .eq('business_id', businessId);
  }

  Future<void> updateRole(String partnerId, String role, String businessId) async {
    await _client
        .from('business_partners')
        .update({'role': role})
        .eq('id', partnerId)
        .eq('business_id', businessId);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from('business_partners').update({
      if (data['full_name'] != null) 'full_name': data['full_name'],
      if (data['phone'] != null) 'phone': data['phone'],
      if (data['role'] != null) 'role': data['role'],
    }).eq('id', id);
  }

  Future<void> remove(String id) async {
    final deleted = await _client
        .from('business_partners')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete rejected by the server (0 rows affected). '
        'A Supabase RLS DELETE policy is likely missing on the business_partners table.',
      );
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfiles(
    List<Map<String, dynamic>> rows,
  ) async {
    final ids = rows
        .map((r) => r['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) return const {};
    final profiles = await _client
        .from('user_profiles')
        .select('user_id, full_name, phone, city')
        .inFilter('user_id', ids);
    return {for (final p in profiles) p['user_id'] as String: p};
  }

  Map<String, dynamic> _mergeProfile(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profiles,
  ) {
    final userId = row['user_id'] as String?;
    final profile = userId == null ? null : profiles[userId];
    if (profile != null) {
      row['full_name'] ??= profile['full_name'];
      row['phone'] ??= profile['phone'];
      row['city'] ??= profile['city'];
    }
    return row;
  }
}
