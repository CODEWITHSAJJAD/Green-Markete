import 'package:flutter/foundation.dart';

import '../../data/models/market_model.dart';
import '../../data/repositories/market_repository.dart';

class MarketProvider extends ChangeNotifier {
  MarketProvider(this._repo);

  final MarketRepository _repo;

  List<MarketModel> _markets = const [];
  List<MarketModel> get markets => _markets;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId, {String? city}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _markets = await _repo.list(businessId, city: city);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MarketModel?> create(Map<String, dynamic> data) async {
    try {
      final market = await _repo.create(data);
      await load(data['business_id'] as String);
      return market;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
