import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/market_model.dart';

class MarketRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<MarketModel>> list(String businessId, {String? city}) async {
    var query = _client
        .from('markets')
        .select()
        .eq('business_id', businessId);
    if (city != null && city.isNotEmpty) query = query.eq('city', city);
    final rows = await query.order('name');
    return rows.map(MarketModel.fromJson).toList();
  }

  Future<MarketModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from('markets')
        .insert({
          'business_id': data['business_id'],
          'name': data['name'],
          'city': data['city'],
          'address': data['address'],
          'stall_number': data['stall_number'],
          'market_type': data['market_type'],
        })
        .select()
        .single();
    return MarketModel.fromJson(row);
  }

  Future<MarketModel> update(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from('markets')
        .update({
          'name': data['name'],
          'city': data['city'],
          'address': data['address'],
          'stall_number': data['stall_number'],
          'market_type': data['market_type'],
        })
        .eq('id', id)
        .select()
        .single();
    return MarketModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    final deleted = await _client
        .from('markets')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete rejected by the server (0 rows affected). '
        'A Supabase RLS DELETE policy is likely missing on the markets table.',
      );
    }
  }
}
