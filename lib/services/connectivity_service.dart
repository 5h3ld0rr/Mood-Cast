import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize() {
    _checkInitialConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If any result is not 'none', we consider it online
    final bool online = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (isOnline.value != online) {
      debugPrint('Connectivity Changed: ${online ? "ONLINE" : "OFFLINE"}');
      isOnline.value = online;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
