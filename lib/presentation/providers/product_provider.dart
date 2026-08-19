import 'package:flutter/foundation.dart';

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._repo);

  final ProductRepository _repo;

  List<ProductModel> _products = const [];
  List<ProductModel> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId, {String? category}) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _products = await _repo.list(businessId, category: category);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductModel?> create(Map<String, dynamic> data) async {
    try {
      final product = await _repo.create(data);
      _products = [..._products, product];
      notifyListeners();
      return product;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<ProductModel?> update(String id, Map<String, dynamic> data) async {
    try {
      final product = await _repo.update(id, data);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final updated = [..._products];
        updated[index] = product;
        _products = updated;
        notifyListeners();
      }
      return product;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      _products = _products.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<ProductModel?> get(String id) async {
    try {
      return await _repo.get(id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}