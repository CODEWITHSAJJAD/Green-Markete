import 'package:flutter/foundation.dart';

import '../../data/models/packing_type_model.dart';
import '../../data/repositories/packing_type_repository.dart';

class PackingTypeProvider extends ChangeNotifier {
  PackingTypeProvider(this._repo);

  final PackingTypeRepository _repo;

  List<PackingTypeModel> _types = const [];
  List<PackingTypeModel> get types => _types;

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
      _types = await _repo.list(businessId);
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
    required double kgCapacity,
  }) async {
    try {
      await _repo.create(businessId: businessId, name: name, kgCapacity: kgCapacity);
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
    required double kgCapacity,
  }) async {
    try {
      await _repo.update(id: id, name: name, kgCapacity: kgCapacity);
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
      _types = _types.where((t) => t.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
