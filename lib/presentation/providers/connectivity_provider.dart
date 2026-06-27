import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connectivity_service.dart';

final connectivityStateProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().onConnectivityChanged;
});
