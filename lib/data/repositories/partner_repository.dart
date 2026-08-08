import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/partner_model.dart';

class PartnerRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<PartnerModel>> list(String businessId) async {
    final rows = await _client
        .from('business_partners')
        .select('*, user_profiles(full_name, phone, city)')
        .eq('business_id', businessId)
        .order('created_at', ascending: true);
    return rows.map(_mergeProfile).map(PartnerModel.fromJson).toList();
  }

  Future<List<PartnerModel>> search(String query, String businessId) async {
    final rows = await _client
        .from('business_partners')
        .select('*, user_profiles(full_name, phone, city)')
        .eq('business_id', businessId)
        .or('full_name.ilike.%$query%,phone.ilike.%$query%')
        .order('full_name');
    return rows.map(_mergeProfile).map(PartnerModel.fromJson).toList();
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

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from('business_partners').update({
      if (data['full_name'] != null) 'full_name': data['full_name'],
      if (data['phone'] != null) 'phone': data['phone'],
      if (data['role'] != null) 'role': data['role'],
    }).eq('id', id);
  }

  Future<void> remove(String id) async {
    await _client.from('business_partners').delete().eq('id', id);
  }

  Map<String, dynamic> _mergeProfile(Map<String, dynamic> row) {
    final profile = row.remove('user_profiles');
    if (profile is Map<String, dynamic>) {
      row['full_name'] ??= profile['full_name'];
      row['phone'] ??= profile['phone'];
      row['city'] ??= profile['city'];
      row['user_id'] ??= row['user_id'];
    }
    return row;
  }
}
