import 'package:flutter/foundation.dart';

import '../../data/models/measurement_unit_model.dart';
import '../../data/repositories/measurement_unit_repository.dart';

class MeasurementUnitProvider extends ChangeNotifier {
  MeasurementUnitProvider(this._repo);

  final MeasurementUnitRepository _repo;

  List<MeasurementUnitModel> _units = const [];
  List<MeasurementUnitModel> get units => _units;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _units = await _repo.list(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String businessId,
    required String name,
    required double kgPerUnit,
  }) async {
    try {
      await _repo.create(businessId: businessId, name: name, kgPerUnit: kgPerUnit);
      await load(businessId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> update({
    required String id,
    required String businessId,
    required String name,
    required double kgPerUnit,
  }) async {
    try {
      await _repo.update(id: id, name: name, kgPerUnit: kgPerUnit);
      await load(businessId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      _units = _units.where((u) => u.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
