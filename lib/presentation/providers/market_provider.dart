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
    await Future<void>.value();
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

  Future<MarketModel?> update(String id, Map<String, dynamic> data) async {
    try {
      final market = await _repo.update(id, data);
      await load(market.businessId);
      return market;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      _markets = _markets.where((m) => m.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}