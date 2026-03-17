import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

enum AlarmType { water, movement, bloodPressure }

class AlarmData {
  final AlarmType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const AlarmData({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class AlarmService {
  static final AlarmService instance = AlarmService._();
  AlarmService._();

  final _alarmController = StreamController<AlarmData?>.broadcast();
  Stream<AlarmData?> get alarmStream => _alarmController.stream;

  final AudioPlayer _player = AudioPlayer();
  Timer? _waterTimer;
  Timer? _movementTimer;
  Timer? _bpTimer;

  bool _running = false;
  DateTime _lastActivity = DateTime.now();
  int _lastStepCount = 0;

  // Call this when user interacts or steps change
  void reportActivity() {
    _lastActivity = DateTime.now();
  }

  void reportSteps(int steps) {
    if (steps > _lastStepCount) {
      _lastStepCount = steps;
      _lastActivity = DateTime.now();
    }
  }

  void startTimers({
    required int waterMinutes,
    required int movementMinutes,
    required int bpMinutes,
    required bool waterEnabled,
    required bool movementEnabled,
    required bool bpEnabled,
  }) {
    stopTimers();
    _running = true;

    if (waterEnabled && waterMinutes > 0) {
      _waterTimer = Timer.periodic(Duration(minutes: waterMinutes), (_) {
        if (_running) _triggerAlarm(const AlarmData(
          type: AlarmType.water,
          title: 'Su İçme Zamanı!',
          message: 'Bir bardak su iç, kalbin sana teşekkür edecek.\nYeterli su tüketimi kan basıncını dengeler ve kalbin daha verimli çalışmasını sağlar.',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF42A5F5),
        ));
      });
    }

    if (movementEnabled) {
      // Check inactivity every minute, trigger if inactive > movementMinutes (default 60)
      final inactivityThreshold = movementMinutes > 0 ? movementMinutes : 60;
      _movementTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!_running) return;
        final inactiveMinutes = DateTime.now().difference(_lastActivity).inMinutes;
        if (inactiveMinutes >= inactivityThreshold) {
          _triggerAlarm(AlarmData(
            type: AlarmType.movement,
            title: 'Çok Uzun Süredir Hareketsizsin!',
            message: '$inactiveMinutes dakikadır hareket etmedin.\nAyağa kalk, biraz yürü. 5 dakikalık yürüyüş bile kan dolaşımını iyileştirir ve kalp sağlığını korur.',
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFFFF9800),
          ));
          // Reset so it doesn't fire every minute
          _lastActivity = DateTime.now();
        }
      });
    }

    if (bpEnabled && bpMinutes > 0) {
      _bpTimer = Timer.periodic(Duration(minutes: bpMinutes), (_) {
        if (_running) _triggerAlarm(const AlarmData(
          type: AlarmType.bloodPressure,
          title: 'Tansiyon Ölçüm Zamanı!',
          message: 'Tansiyonunu ölçmeyi unutma.\nDüzenli takip kalp sağlığının temelidir. 5 dakika dinlendikten sonra ölç.',
          icon: Icons.monitor_heart_rounded,
          color: Color(0xFFE53935),
        ));
      });
    }
  }

  void stopTimers() {
    _running = false;
    _waterTimer?.cancel();
    _movementTimer?.cancel();
    _bpTimer?.cancel();
    _waterTimer = null;
    _movementTimer = null;
    _bpTimer = null;
  }

  Future<void> _triggerAlarm(AlarmData alarm) async {
    _alarmController.add(alarm);

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 300, 150, 300, 150, 500], intensities: [0, 200, 0, 200, 0, 255]);
      }
    } catch (_) {}

    try {
      await _player.play(AssetSource('alarm.mp3'));
    } catch (_) {}
  }

  void dismissAlarm() {
    _alarmController.add(null);
    _player.stop();
    try { Vibration.cancel(); } catch (_) {}
  }

  void dispose() {
    stopTimers();
    _alarmController.close();
    _player.dispose();
  }
}
