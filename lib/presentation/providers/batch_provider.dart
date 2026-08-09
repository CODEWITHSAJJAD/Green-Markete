import 'package:flutter/foundation.dart';

import '../../data/models/batch_model.dart';
import '../../data/models/batch_vehicle_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/packing_return_model.dart';
import '../../data/models/packing_record_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/batch_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/sale_repository.dart';

/// Dedicated list for the Sales tab (selling batches only).
///
/// Kept as its own provider type (separate from [BatchListProvider]) so the
/// Batches and Sales tabs don't share one mutable dataset with different
/// status filters — the two startup loads used to race and clobber each other.
class SellingBatchesProvider extends BatchListProvider {
  SellingBatchesProvider(super.repo);
}

class BatchListProvider extends ChangeNotifier {
  BatchListProvider(this._repo);

  final BatchRepository _repo;

  List<BatchModel> _batches = const [];
  List<BatchModel> get batches => _batches;

  String? _activeBusinessId;
  String? _activeStatus;
  String? _activeProductId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  Future<void> load(String businessId, {String? status, String? productId}) async {
    _isLoading = true;
    _hasMore = true;
    _activeBusinessId = businessId;
    _activeStatus = status;
    _activeProductId = productId;
    _error = null;
    notifyListeners();
    try {
      final items = await _repo.list(
        businessId: businessId,
        status: status,
        productId: productId,
      );
      _batches = items;
      _hasMore = items.length >= 50;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _batches.isEmpty) return;
    final businessId = _activeBusinessId;
    if (businessId == null) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final lastCreatedAt = _batches.last.createdAt;
      final more = await _repo.list(
        businessId: businessId,
        status: _activeStatus,
        productId: _activeProductId,
        cursor: lastCreatedAt,
      );
      _batches = [..._batches, ...more];
      _hasMore = more.length >= 50;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void removeById(String batchId) {
    _batches = _batches.where((b) => b.id != batchId).toList();
    notifyListeners();
  }

  Future<bool> create(BatchCreateRequest request) async {
    try {
      final batch = await _repo.create(request);
      _batches = [batch, ..._batches];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

class BatchDetailProvider extends ChangeNotifier {
  BatchDetailProvider(this._repo);

  final BatchRepository _repo;

  BatchModel? _batch;
  BatchModel? get batch => _batch;

  List<PackingRecordModel> _packingRecords = const [];
  List<PackingRecordModel> get packingRecords => _packingRecords;

  List<BatchVehicleModel> _vehicleLoads = const [];
  List<BatchVehicleModel> get vehicleLoads => _vehicleLoads;

  List<PackingReturnModel> _returns = const [];
  List<PackingReturnModel> get returns => _returns;

  List<Map<String, dynamic>> _batchPartners = const [];
  List<Map<String, dynamic>> get batchPartners => _batchPartners;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String id) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _batch = await _repo.get(id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    await _loadPacking(id);
    await _loadVehicles(id);
    await _loadReturns(id);
    await _loadBatchPartners(id);
  }

  Future<void> _loadPacking(String id) async {
    try {
      _packingRecords = await _repo.listPacking(id);
    } catch (e) {
      _packingRecords = const [];
      _error ??= e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVehicles(String id) async {
    try {
      _vehicleLoads = await _repo.listVehicles(id);
    } catch (e) {
      _vehicleLoads = const [];
      _error ??= e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<void> addVehicleLoad(VehicleLoadCreate load) async {
    final id = _batch?.id;
    if (id == null) return;
    await _repo.addVehicleLoad(id, load);
    await _loadVehicles(id);
  }

  Future<void> deleteVehicleLoad(String loadId) async {
    final id = _batch?.id;
    if (id == null) return;
    await _repo.deleteVehicleLoad(loadId);
    await _loadVehicles(id);
  }

  Future<void> _loadReturns(String id) async {
    try {
      _returns = await _repo.listReturns(id);
    } catch (e) {
      _returns = const [];
      _error ??= e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<void> addReturn(PackingReturnCreate item) async {
    final id = _batch?.id;
    if (id == null) return;
    await _repo.addReturn(id, item);
    await _loadReturns(id);
  }

  Future<void> deleteReturn(String returnId) async {
    final id = _batch?.id;
    if (id == null) return;
    await _repo.deleteReturn(returnId);
    await _loadReturns(id);
  }

  Future<void> _loadBatchPartners(String id) async {
    try {
      _batchPartners = await _repo.listBatchPartners(id);
    } catch (e) {
      _batchPartners = const [];
      _error ??= e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String status, {String? id}) async {
    final batchId = id ?? _batch?.id;
    if (batchId == null) return false;
    try {
      await _repo.updateStatus(batchId, status);
      if (_batch?.id == batchId) await load(batchId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> addPacking(PackingRecordCreate packing) async {
    final id = _batch?.id;
    if (id == null) return;
    await _repo.addPacking(id, packing);
    await load(id);
  }

  Future<void> addPartner(BatchPartnerCreate partner) async {
    final id = _batch?.id;
    if (id == null) return;
    await _repo.addPartner(id, partner);
    await load(id);
  }
}

class BatchPLProvider extends ChangeNotifier {
  BatchPLProvider(this._repo);

  final BatchRepository _repo;

  BatchPLDetailModel? _pl;
  BatchPLDetailModel? get pl => _pl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String batchId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _pl = await _repo.getSummary(batchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._repo);

  final ExpenseRepository _repo;

  List<ExpenseModel> _expenses = const [];
  List<ExpenseModel> get expenses => _expenses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load(String batchId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _expenses = await _repo.list(batchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String batchId, ExpenseCreate expense) async {
    try {
      await _repo.create(batchId, expense);
      await load(batchId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> voidExpense(String id, String reason) async {
    try {
      await _repo.voidExpense(id, reason: reason);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, ExpenseUpdateModel expense) async {
    try {
      await _repo.update(id, expense);
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
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

class SaleProvider extends ChangeNotifier {
  SaleProvider(this._repo);

  final SaleRepository _repo;

  List<SaleModel> _sales = const [];
  List<SaleModel> get sales => _sales;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadByBatch(String batchId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _sales = await _repo.listByBatch(batchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadByCustomer(String customerId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _sales = await _repo.listByCustomer(customerId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(SaleCreateRequest request) async {
    try {
      await _repo.create(request);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}