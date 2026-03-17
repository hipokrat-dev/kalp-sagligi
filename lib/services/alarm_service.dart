import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

enum AlarmType { water, movement, bloodPressure }

class AlarmData {
  final AlarmType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String soundAsset;

  const AlarmData({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.soundAsset,
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
  Timer? _snoozeTimer;

  bool _running = false;
  DateTime _lastActivity = DateTime.now();
  int _lastStepCount = 0;

  // Quiet hours
  int _quietStart = 22; // 22:00
  int _quietEnd = 8;    // 08:00

  bool get _isQuietHours {
    final hour = DateTime.now().hour;
    if (_quietStart > _quietEnd) {
      return hour >= _quietStart || hour < _quietEnd;
    }
    return hour >= _quietStart && hour < _quietEnd;
  }

  void setQuietHours(int start, int end) {
    _quietStart = start;
    _quietEnd = end;
  }

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
        if (_running && !_isQuietHours) {
          _triggerAlarm(const AlarmData(
            type: AlarmType.water,
            title: 'Su İçme Zamanı!',
            message: 'Bir bardak su iç, kalbin sana teşekkür edecek.\nYeterli su tüketimi kan basıncını dengeler.',
            icon: Icons.water_drop_rounded,
            color: Color(0xFF42A5F5),
            soundAsset: 'water_reminder.wav',
          ));
        }
      });
    }

    if (movementEnabled) {
      final threshold = movementMinutes > 0 ? movementMinutes : 60;
      _movementTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!_running || _isQuietHours) return;
        final inactiveMin = DateTime.now().difference(_lastActivity).inMinutes;
        if (inactiveMin >= threshold) {
          _triggerAlarm(AlarmData(
            type: AlarmType.movement,
            title: '$inactiveMin Dakikadır Hareketsizsin!',
            message: 'Ayağa kalk ve biraz yürü.\n5 dakikalık yürüyüş bile kan dolaşımını iyileştirir.',
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFFFF9800),
            soundAsset: 'movement_reminder.wav',
          ));
          _lastActivity = DateTime.now();
        }
      });
    }

    if (bpEnabled && bpMinutes > 0) {
      _bpTimer = Timer.periodic(Duration(minutes: bpMinutes), (_) {
        if (_running && !_isQuietHours) {
          _triggerAlarm(const AlarmData(
            type: AlarmType.bloodPressure,
            title: 'Tansiyon Ölçüm Zamanı!',
            message: 'Tansiyonunu ölçmeyi unutma.\n5 dakika dinlendikten sonra ölç.',
            icon: Icons.monitor_heart_rounded,
            color: Color(0xFFE53935),
            soundAsset: 'bp_reminder.wav',
          ));
        }
      });
    }
  }

  void stopTimers() {
    _running = false;
    _waterTimer?.cancel();
    _movementTimer?.cancel();
    _bpTimer?.cancel();
    _snoozeTimer?.cancel();
    _waterTimer = null;
    _movementTimer = null;
    _bpTimer = null;
    _snoozeTimer = null;
  }

  Future<void> _triggerAlarm(AlarmData alarm) async {
    _alarmController.add(alarm);

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Type-specific vibration
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        switch (alarm.type) {
          case AlarmType.water:
            Vibration.vibrate(pattern: [0, 200, 100, 200], intensities: [0, 150, 0, 150]);
          case AlarmType.movement:
            Vibration.vibrate(pattern: [0, 300, 150, 300, 150, 500], intensities: [0, 200, 0, 200, 0, 255]);
          case AlarmType.bloodPressure:
            Vibration.vibrate(pattern: [0, 400, 200, 400], intensities: [0, 180, 0, 180]);
        }
      }
    } catch (_) {}

    // Play type-specific sound
    try {
      await _player.setVolume(0.7);
      await _player.play(AssetSource(alarm.soundAsset));
    } catch (_) {
      try {
        await _player.play(AssetSource('notification.wav'));
      } catch (_) {}
    }

    // Auto-dismiss after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      dismissAlarm();
    });
  }

  void snoozeAlarm(AlarmData alarm, {int minutes = 5}) {
    dismissAlarm();
    _snoozeTimer?.cancel();
    _snoozeTimer = Timer(Duration(minutes: minutes), () {
      if (_running && !_isQuietHours) {
        _triggerAlarm(alarm);
      }
    });
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
