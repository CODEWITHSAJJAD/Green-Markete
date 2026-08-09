import 'package:flutter/foundation.dart';

/// App-wide signal fired after any successful data mutation so every main
/// screen that shares a dataset can reload with fresh data.
///
/// Screens hold the same provider instances (registered once in `main.dart`),
/// so a mutation on one screen leaves the other screens' cached state stale.
/// Any screen that writes data calls [DataRefreshNotifier.instance.refresh]
/// with the active business id, and `MainShell` (which owns the tabs) listens
/// and reloads the shared tab datasets.
class DataRefreshNotifier extends ChangeNotifier {
  DataRefreshNotifier._();

  static final DataRefreshNotifier instance = DataRefreshNotifier._();

  String? _lastBusinessId;
  String? get lastBusinessId => _lastBusinessId;

  void refresh(String businessId) {
    _lastBusinessId = businessId;
    notifyListeners();
  }
}
