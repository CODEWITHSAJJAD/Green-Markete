import 'package:shared_preferences/shared_preferences.dart';
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
    final enriched = await _enrichMemberTypes(rows);
    return enriched.map((r) => _mergeProfile(r, profiles)).map(PartnerModel.fromJson).toList();
  }

  Future<List<PartnerModel>> search(String query, String businessId) async {
    final rows = await _client
        .from('business_partners')
        .select()
        .eq('business_id', businessId)
        .or('full_name.ilike.%$query%,phone.ilike.%$query%')
        .order('full_name');
    final profiles = await _fetchProfiles(rows);
    final enriched = await _enrichMemberTypes(rows);
    return enriched.map((r) => _mergeProfile(r, profiles)).map(PartnerModel.fromJson).toList();
  }

  Future<PartnerModel> create(Map<String, dynamic> data) async {
    final memberType = data['member_type']?.toString() ?? 'employee';
    final insertData = <String, dynamic>{
      'business_id': data['business_id'],
      'full_name': data['full_name'],
      'phone': data['phone'],
      'role': data['role'] ?? 'partner',
      'access_level': data['access_level'] ?? 'viewer',
      'manage_other_side': data['manage_other_side'] ?? false,
      'is_claimed': false,
    };

    Map<String, dynamic> row;
    try {
      row = await _client
          .from('business_partners')
          .insert({...insertData, 'member_type': memberType})
          .select()
          .single();
    } catch (_) {
      row = await _client
          .from('business_partners')
          .insert(insertData)
          .select()
          .single();
    }

    final id = row['id']?.toString();
    if (id != null) {
      await _saveLocalMemberType(id, memberType);
    }
    row['member_type'] = memberType;
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

  Future<void> updatePermission(
    String partnerId,
    String permissionKey,
    bool isGranted,
    String businessId,
  ) async {
    try {
      final current = await _client
          .from('business_partners')
          .select('permissions')
          .eq('id', partnerId)
          .eq('business_id', businessId)
          .maybeSingle();

      final existing = (current?['permissions'] as Map<String, dynamic>?) ?? {};
      final updated = Map<String, dynamic>.from(existing);
      updated[permissionKey] = isGranted;

      await _client
        .from('business_partners')
        .update({'permissions': updated})
        .eq('id', partnerId)
        .eq('business_id', businessId);
    } catch (_) {
      // If table doesn't have permissions column, fallback gracefully
      if (permissionKey == 'can_purchase' || permissionKey == 'can_sell') {
        await updateManageOtherSide(partnerId, isGranted, businessId);
      } else if (permissionKey == 'can_close_batch') {
        await updateAccess(partnerId, isGranted ? 'editor' : 'viewer', businessId);
      }
    }
  }

  Future<void> updateRole(String partnerId, String role, String businessId) async {
    await _client
        .from('business_partners')
        .update({'role': role})
        .eq('id', partnerId)
        .eq('business_id', businessId);
  }

  Future<void> updateMemberType(String partnerId, String memberType, String businessId) async {
    // 1. Save locally so it's instantly and permanently remembered
    await _saveLocalMemberType(partnerId, memberType);

    // 2. Try updating member_type column directly
    try {
      await _client
          .from('business_partners')
          .update({'member_type': memberType})
          .eq('id', partnerId)
          .eq('business_id', businessId);
    } catch (_) {}

    // 3. Try storing in permissions json column for cross-device sync
    try {
      final current = await _client
          .from('business_partners')
          .select('permissions')
          .eq('id', partnerId)
          .eq('business_id', businessId)
          .maybeSingle();

      final existing = (current?['permissions'] as Map<String, dynamic>?) ?? {};
      final updated = Map<String, dynamic>.from(existing);
      updated['member_type'] = memberType;

      await _client
          .from('business_partners')
          .update({'permissions': updated})
          .eq('id', partnerId)
          .eq('business_id', businessId);
    } catch (_) {}
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

  Future<void> _saveLocalMemberType(String partnerId, String memberType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('partner_member_type_$partnerId', memberType);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _enrichMemberTypes(List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return rows.map((r) {
        final row = Map<String, dynamic>.from(r);
        final id = row['id']?.toString();
        final localType = id != null ? prefs.getString('partner_member_type_$id') : null;
        if (localType != null) {
          row['member_type'] = localType;
        } else if (row['permissions'] is Map && (row['permissions'] as Map)['member_type'] != null) {
          row['member_type'] = (row['permissions'] as Map)['member_type'].toString();
        }
        return row;
      }).toList();
    } catch (_) {
      return rows;
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
