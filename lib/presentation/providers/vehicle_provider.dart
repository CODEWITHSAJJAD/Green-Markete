import 'package:flutter/foundation.dart';

import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleProvider(this._repo);

  final VehicleRepository _repo;

  List<VehicleModel> _vehicles = const [];
  List<VehicleModel> get vehicles => _vehicles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _vehicles = await _repo.list(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VehicleModel?> create(Map<String, dynamic> data) async {
    try {
      final vehicle = await _repo.create(data);
      await load(data['business_id'] as String);
      return vehicle;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<VehicleModel?> update(String id, Map<String, dynamic> data) async {
    try {
      final vehicle = await _repo.update(id, data);
      final businessId = vehicle.businessId;
      await load(businessId);
      return vehicle;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      _vehicles = _vehicles.where((v) => v.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
