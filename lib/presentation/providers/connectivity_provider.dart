import 'package:flutter/foundation.dart';

import '../../core/supabase/supabase_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> check() async {
    _isOnline = await SupabaseService.instance.isConnected();
    notifyListeners();
  }
}
