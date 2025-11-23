import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../services/sms_service.dart';

class SyncProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final SmsService _smsService = SmsService();

  bool _isSyncing = false;
  int _syncProgress = 0;
  int _totalToSync = 0;
  String? _syncError;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  int get syncProgress => _syncProgress;
  int get totalToSync => _totalToSync;
  String? get syncError => _syncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isLoggedIn => _supabaseService.currentUser != null;

  double get syncProgressPercent =>
      _totalToSync > 0 ? _syncProgress / _totalToSync : 0.0;

  // Start cloud sync
  Future<void> startSync() async {
    if (!isLoggedIn) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      await _smsService.startSync();
      _lastSyncTime = DateTime.now();
      _syncError = null;
    } catch (e) {
      _syncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Stop cloud sync
  Future<void> stopSync() async {
    await _smsService.stopSync();
    _lastSyncTime = null;
    notifyListeners();
  }

  // Restore messages from cloud
  Future<void> restoreFromCloud() async {
    if (!isLoggedIn) return;

    _isSyncing = true;
    _syncProgress = 0;
    _syncError = null;
    notifyListeners();

    try {
      await _smsService.restoreFromCloud();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _syncError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Update sync progress (called by services)
  void updateProgress(int progress, int total) {
    _syncProgress = progress;
    _totalToSync = total;
    notifyListeners();
  }

  // Clear sync state
  void clearError() {
    _syncError = null;
    notifyListeners();
  }
}
