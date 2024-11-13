import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  ConnectivityService() {
    _initializeConnectivity();
  }

  void _initializeConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isConnected = connectivityResult != ConnectivityResult.none;
    notifyListeners(); // Notify listeners about initial status

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      notifyListeners(); // Notify listeners on connectivity change
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
