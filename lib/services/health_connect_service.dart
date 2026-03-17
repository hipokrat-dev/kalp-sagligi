import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthConnectService {
  static final HealthConnectService instance = HealthConnectService._();
  HealthConnectService._();

  bool _available = false;
  bool _permitted = false;

  bool get isAvailable => _available;
  bool get isPermitted => _permitted;

  Future<bool> checkAvailability() async {
    try {
      _available = await Health().isHealthConnectAvailable();
      return _available;
    } catch (e) {
      debugPrint('Health Connect availability check failed: $e');
      _available = false;
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (!_available) await checkAvailability();
      if (!_available) return false;

      Health().configure();
      final granted = await Health().requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      _permitted = granted;
      return granted;
    } catch (e) {
      debugPrint('Health Connect permission request failed: $e');
      _permitted = false;
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    try {
      if (!_available) return false;
      final result = await Health().hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      _permitted = result ?? false;
      return _permitted;
    } catch (e) {
      debugPrint('Health Connect permission check failed: $e');
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    try {
      if (!_permitted) {
        final hasPerms = await checkPermissions();
        if (!hasPerms) return 0;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final steps = await Health().getTotalStepsInInterval(startOfDay, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Health Connect get steps failed: $e');
      return 0;
    }
  }
}
