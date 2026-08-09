import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<VehicleModel>> list(String businessId) async {
    final rows = await _client
        .from('vehicles')
        .select()
        .eq('business_id', businessId)
        .order('plate_number');
    return rows.map(VehicleModel.fromJson).toList();
  }

  Future<VehicleModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from('vehicles')
        .insert({
          'business_id': data['business_id'],
          'plate_number': data['plate_number'],
          'driver_name': data['driver_name'],
          'driver_phone': data['driver_phone'],
          'capacity_value': data['capacity_value'],
          'capacity_unit': data['capacity_unit'],
          'notes': data['notes'],
        })
        .select()
        .single();
    return VehicleModel.fromJson(row);
  }

  Future<VehicleModel> update(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from('vehicles')
        .update({
          'plate_number': data['plate_number'],
          'driver_name': data['driver_name'],
          'driver_phone': data['driver_phone'],
          'capacity_value': data['capacity_value'],
          'capacity_unit': data['capacity_unit'],
          'notes': data['notes'],
        })
        .eq('id', id)
        .select()
        .single();
    return VehicleModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }
}
