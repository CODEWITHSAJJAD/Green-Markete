import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/remote/partner_remote_ds.dart';
import '../models/partner_model.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(ref.watch(partnerRemoteDsProvider));
});

class PartnerRepository {
  final PartnerRemoteDs _remoteDs;
  PartnerRepository(this._remoteDs);

  Future<List<PartnerModel>> search(String query, String businessId) {
    return _remoteDs.search(query, businessId);
  }

  Future<List<PartnerModel>> list(String businessId) {
    return _remoteDs.list(businessId);
  }

  Future<PartnerModel> create(Map<String, dynamic> data) {
    return _remoteDs.create(data);
  }

  Future<void> invite(String partnerId) {
    return _remoteDs.invite(partnerId);
  }

  Future<void> updateAccess(String partnerId, String accessLevel, String businessId) {
    return _remoteDs.updateAccess(partnerId, accessLevel, businessId);
  }
}
