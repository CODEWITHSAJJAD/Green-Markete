import 'package:flutter/foundation.dart';

class AsyncNotifier<T> extends ChangeNotifier {
  AsyncNotifier({T? initialValue}) : _value = initialValue;

  T? _value;
  T? get value => _value;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> run(Future<T> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await action();
      _value = result;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setValue(T value) {
    _value = value;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
