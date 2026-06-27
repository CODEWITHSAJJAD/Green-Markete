import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/partner_model.dart';
import '../../data/repositories/partner_repository.dart';
import '../pages/partners/partner_directory_page.dart';
import 'auth_provider.dart';

final partnerSearchProvider = FutureProvider.family<List<PartnerModel>, Map<String, dynamic>>((ref, params) async {
  final query = params['query'] as String? ?? '';
  final businessId = params['business_id'] as String? ?? '';
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.search(query, businessId);
});

final partnerListProvider = FutureProvider.family<List<PartnerModel>, String>((ref, businessId) async {
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.list(businessId);
});

class PartnerSearchNotifier extends StateNotifier<AsyncValue<List<PartnerModel>>> {
  final PartnerRepository _repo;
  final Debouncer _debouncer = Debouncer();

  PartnerSearchNotifier(this._repo) : super(const AsyncData([]));

  void search(String query, String businessId) {
    if (query.length < 3) {
      state = const AsyncData([]);
      return;
    }
    _debouncer(() async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _repo.search(query, businessId));
    });
  }
}

final partnerSearchNotifierProvider = StateNotifierProvider<PartnerSearchNotifier, AsyncValue<List<PartnerModel>>>((ref) {
  return PartnerSearchNotifier(ref.watch(partnerRepositoryProvider));
});
