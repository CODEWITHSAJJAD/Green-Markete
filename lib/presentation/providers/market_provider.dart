import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/market_model.dart';
import '../../data/repositories/market_repository.dart';

final marketListProvider = FutureProvider.family<List<MarketModel>, String>((ref, businessId) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.list(businessId);
});

final marketsByCityProvider = FutureProvider.family<List<MarketModel>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.list(params['business_id'] as String, city: params['city'] as String?);
});
