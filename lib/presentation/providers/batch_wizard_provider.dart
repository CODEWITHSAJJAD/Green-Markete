import 'package:flutter/foundation.dart';

class BatchWizardProvider extends ChangeNotifier {
  int _currentStep = 0;
  int get currentStep => _currentStep;

  String? _productId;
  String? get productId => _productId;

  String? _sourceMarketId;
  String? get sourceMarketId => _sourceMarketId;

  String? _destinationMarketId;
  String? get destinationMarketId => _destinationMarketId;

  String? _purchaseDate;
  String? get purchaseDate => _purchaseDate;

  double? _totalQuantity;
  double? get totalQuantity => _totalQuantity;

  String? _quantityUnit;
  String? get quantityUnit => _quantityUnit;

  double? _purchasePricePerUnit;
  double? get purchasePricePerUnit => _purchasePricePerUnit;

  String? _transportPaidBy;
  String? get transportPaidBy => _transportPaidBy;

  List<Map<String, dynamic>> _partners = const [];
  List<Map<String, dynamic>> get partners => _partners;

  List<Map<String, dynamic>> _packingRecords = const [];
  List<Map<String, dynamic>> get packingRecords => _packingRecords;

  List<Map<String, dynamic>> _expenses = const [];
  List<Map<String, dynamic>> get expenses => _expenses;

  void nextStep() {
    if (_currentStep < 4) {
      _currentStep += 1;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep -= 1;
      notifyListeners();
    }
  }

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void updateProduct(String productId) {
    _productId = productId;
    notifyListeners();
  }

  void updateMarkets(String? source, String? destination) {
    _sourceMarketId = source;
    _destinationMarketId = destination;
    notifyListeners();
  }

  void updatePurchaseDetails({
    String? date,
    double? quantity,
    String? unit,
    double? price,
    String? transportPaidBy,
  }) {
    _purchaseDate = date;
    _totalQuantity = quantity;
    _quantityUnit = unit;
    _purchasePricePerUnit = price;
    _transportPaidBy = transportPaidBy;
    notifyListeners();
  }

  void updatePartners(List<Map<String, dynamic>> partners) {
    _partners = partners;
    notifyListeners();
  }

  void updatePackingRecords(List<Map<String, dynamic>> records) {
    _packingRecords = records;
    notifyListeners();
  }

  void updateExpenses(List<Map<String, dynamic>> expenses) {
    _expenses = expenses;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _productId = null;
    _sourceMarketId = null;
    _destinationMarketId = null;
    _purchaseDate = null;
    _totalQuantity = null;
    _quantityUnit = null;
    _purchasePricePerUnit = null;
    _transportPaidBy = null;
    _partners = const [];
    _packingRecords = const [];
    _expenses = const [];
    notifyListeners();
  }
}
