import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_sync_service.dart';

class AutoSyncManager {
  static final AutoSyncManager _instance = AutoSyncManager._internal();
  factory AutoSyncManager() => _instance;
  AutoSyncManager._internal();

  late OfflineSyncService _offlineSyncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void initialize(OfflineSyncService offlineSyncService) {
    _offlineSyncService = offlineSyncService;

    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        debugPrint('AutoSyncManager: Network restored. Triggering auto-sync...');
        _offlineSyncService.syncAll();
      }
    });

    // Lancer une première vérification au démarrage
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
      debugPrint('AutoSyncManager: Initial network present. Triggering auto-sync...');
      _offlineSyncService.syncAll();
    }
  }

  Future<void> triggerSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
      debugPrint('AutoSyncManager: Manual trigger. Network present. Syncing...');
      _offlineSyncService.syncAll();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
