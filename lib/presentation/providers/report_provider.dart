import 'package:flutter/foundation.dart';

import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider(this._repo);

  final ReportRepository _repo;

  PLSummaryModel? _plSummary;
  PLSummaryModel? get plSummary => _plSummary;

  List<CreditReportModel> _credit = const [];
  List<CreditReportModel> get credit => _credit;

  List<CreditReportModel> _overdue = const [];
  List<CreditReportModel> get overdue => _overdue;

  List<MarketPerformanceModel> _marketPerformance = const [];
  List<MarketPerformanceModel> get marketPerformance => _marketPerformance;

  PartnerPLModel? _partnerPL;
  PartnerPLModel? get partnerPL => _partnerPL;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadPLSummary(
    String businessId, {
    String? dateFrom,
    String? dateTo,
  }) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _plSummary = await _repo.getPLSummary(
        businessId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCredit(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _credit = await _repo.getCustomerCredit(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOverdue(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _overdue = await _repo.getOverdueCustomers(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMarketPerformance(String businessId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _marketPerformance = await _repo.getCityMarketPerformance(businessId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPartnerPL(String partnerId, String batchId) async {
    _isLoading = true;
    await Future<void>.value();
    _error = null;
    notifyListeners();
    try {
      _partnerPL = await _repo.getPartnerPL(partnerId, batchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}