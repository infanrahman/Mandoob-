import 'dart:async';
import 'package:flutter/material.dart';

enum SyncStatus {
  synced,
  syncing,
  offline,
  error,
}

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SyncStatus _status = SyncStatus.synced;
  int _pendingChangesCount = 0;
  DateTime _lastSyncTime = DateTime.now();

  SyncStatus get status => _status;
  int get pendingChangesCount => _pendingChangesCount;
  DateTime get lastSyncTime => _lastSyncTime;

  bool get isOffline => _status == SyncStatus.offline;

  void toggleOfflineMode() {
    if (_status == SyncStatus.offline) {
      triggerSync();
    } else {
      _status = SyncStatus.offline;
      notifyListeners();
    }
  }

  void recordOfflineChange() {
    _pendingChangesCount++;
    if (_status != SyncStatus.offline) {
      _status = SyncStatus.synced;
    }
    notifyListeners();
  }

  Future<void> triggerSync() async {
    _status = SyncStatus.syncing;
    notifyListeners();

    // Simulate async sync with cloud server
    await Future.delayed(const Duration(seconds: 2));

    _pendingChangesCount = 0;
    _status = SyncStatus.synced;
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }
}
