import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/market_remote_ds.dart';
import '../models/market_model.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(ref.watch(marketRemoteDsProvider));
});

class MarketRepository {
  final MarketRemoteDs _remoteDs;
  MarketRepository(this._remoteDs);

  Future<List<MarketModel>> list(String businessId, {String? city}) {
    return _remoteDs.list(businessId, city: city);
  }

  Future<MarketModel> create(Map<String, dynamic> data) {
    return _remoteDs.create(data);
  }
}
