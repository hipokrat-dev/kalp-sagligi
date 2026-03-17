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
          message: 'Bir bardak su iç, kalbin sana teşekkür edecek. Günde en az 8 bardak su içmeyi hedefle.',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF42A5F5),
        ));
      });
    }

    if (movementEnabled && movementMinutes > 0) {
      _movementTimer = Timer.periodic(Duration(minutes: movementMinutes), (_) {
        if (_running) _triggerAlarm(const AlarmData(
          type: AlarmType.movement,
          title: 'Hareket Zamanı!',
          message: 'Ayağa kalk ve biraz yürü. 5 dakikalık bir yürüyüş bile kan dolaşımını iyileştirir.',
          icon: Icons.directions_walk_rounded,
          color: Color(0xFFFF9800),
        ));
      });
    }

    if (bpEnabled && bpMinutes > 0) {
      _bpTimer = Timer.periodic(Duration(minutes: bpMinutes), (_) {
        if (_running) _triggerAlarm(const AlarmData(
          type: AlarmType.bloodPressure,
          title: 'Tansiyon Ölçüm Zamanı!',
          message: 'Tansiyonunu ölçmeyi unutma. Düzenli takip kalp sağlığının temelidir.',
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

    // Vibrate
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 300, 150, 300, 150, 500], intensities: [0, 200, 0, 200, 0, 255]);
      }
    } catch (_) {}

    // Sound
    try {
      await _player.play(AssetSource('alarm.mp3'));
    } catch (_) {
      // No alarm sound file, use system default
      try {
        await _player.play(UrlSource('https://invalid.local/noop'));
      } catch (_) {}
    }
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
