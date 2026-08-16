import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/measurement_unit_model.dart';

class MeasurementUnitRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<MeasurementUnitModel>> list(String businessId) async {
    final rows = await _client
        .from('measurement_units')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return rows.map(MeasurementUnitModel.fromJson).toList();
  }

  Future<MeasurementUnitModel> create({
    required String businessId,
    required String name,
    required double kgPerUnit,
  }) async {
    final row = await _client
        .from('measurement_units')
        .insert({
          'business_id': businessId,
          'name': name,
          'kg_per_unit': kgPerUnit,
        })
        .select()
        .single();
    return MeasurementUnitModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    final deleted = await _client
        .from('measurement_units')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete rejected by the server (0 rows affected). '
        'A Supabase RLS DELETE policy is likely missing on the measurement_units table.',
      );
    }
  }
}
