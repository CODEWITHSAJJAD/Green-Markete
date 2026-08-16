import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/packing_type_model.dart';

class PackingTypeRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<PackingTypeModel>> list(String businessId) async {
    final rows = await _client
        .from('packing_types')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return rows.map(PackingTypeModel.fromJson).toList();
  }

  Future<PackingTypeModel> create({
    required String businessId,
    required String name,
    required double kgCapacity,
  }) async {
    final row = await _client
        .from('packing_types')
        .insert({
          'business_id': businessId,
          'name': name,
          'kg_capacity': kgCapacity,
        })
        .select()
        .single();
    return PackingTypeModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    final deleted = await _client
        .from('packing_types')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete rejected by the server (0 rows affected). '
        'A Supabase RLS DELETE policy is likely missing on the packing_types table.',
      );
    }
  }
}
