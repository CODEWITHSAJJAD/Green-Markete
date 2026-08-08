import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/business_model.dart';

class BusinessRepository {
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<BusinessModel> create({
    required String name,
    String? city,
    String businessType = 'multi_partner',
  }) async {
    final userId = _client.auth.currentUser?.id;
    final businessRow = await _client
        .from('businesses')
        .insert({
          'name': name,
          'business_type': businessType,
          'owner_id': userId,
        })
        .select()
        .single();

    await _client.from('business_partners').insert({
      'business_id': businessRow['id'],
      'user_id': userId,
      'full_name': _client.auth.currentUser?.email,
      'phone': _client.auth.currentUser?.phone,
      'role': 'owner',
      'access_level': 'owner',
      'is_claimed': true,
    });

    return BusinessModel.fromJson(businessRow);
  }

  Future<void> updateSettings(
    String businessId, {
    String? name,
    double? creditAlertThreshold,
  }) async {
    await _client.from('businesses').update({
      'name': ?name,
      'credit_alert_threshold': ?creditAlertThreshold,
    }).eq('id', businessId);
  }
}
