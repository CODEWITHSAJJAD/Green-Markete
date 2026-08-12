import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<ProductModel>> list(String businessId, {String? category}) async {
    var query = _client
        .from('products')
        .select()
        .eq('business_id', businessId);
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    final rows = await query.order('name');
    return rows.map(ProductModel.fromJson).toList();
  }

  Future<ProductModel> create(Map<String, dynamic> data) async {
    final row = await _client
        .from('products')
        .insert({
          'business_id': data['business_id'],
          'name': data['name'],
          'category': data['category'],
          'base_unit': data['base_unit'] ?? data['default_unit'] ?? 'kg',
        })
        .select()
        .single();
    return ProductModel.fromJson(row);
  }

  Future<ProductModel> get(String id) async {
    final row = await _client.from('products').select().eq('id', id).single();
    return ProductModel.fromJson(row);
  }

  Future<ProductModel> update(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from('products')
        .update({
          'name': data['name'],
          'category': data['category'],
          'base_unit': data['base_unit'] ?? data['default_unit'] ?? 'kg',
        })
        .eq('id', id)
        .select()
        .single();
    return ProductModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    final deleted = await _client
        .from('products')
        .delete()
        .eq('id', id)
        .select();
    if (deleted.isEmpty) {
      throw Exception(
        'Delete rejected by the server (0 rows affected). '
        'A Supabase RLS DELETE policy is likely missing on the products table.',
      );
    }
  }
}
