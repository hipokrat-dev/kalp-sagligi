import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../widgets/alarm_overlay.dart';
import 'home_screen.dart';
import 'blood_pressure_screen.dart';
import 'risk_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  AlarmData? _activeAlarm;
  StreamSubscription? _alarmSub;

  final _screens = const [
    HomeScreen(),
    BloodPressureScreen(),
    RiskScreen(),
    InfoScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAlarms();
    _alarmSub = AlarmService.instance.alarmStream.listen((alarm) {
      if (mounted) setState(() => _activeAlarm = alarm);
    });
  }

  Future<void> _initAlarms() async {
    final storage = StorageService.instance;
    final waterEnabled = await storage.getReminderEnabled('water');
    final waterMin = await storage.getReminderInterval('water');
    final moveEnabled = await storage.getReminderEnabled('movement');
    final moveMin = await storage.getReminderInterval('movement');
    final bpEnabled = await storage.getReminderEnabled('bp');
    final bpMin = await storage.getReminderInterval('bp');

    AlarmService.instance.startTimers(
      waterMinutes: waterMin,
      movementMinutes: moveMin,
      bpMinutes: bpMin,
      waterEnabled: waterEnabled,
      movementEnabled: moveEnabled,
      bpEnabled: bpEnabled,
    );
  }

  @override
  void dispose() {
    _alarmSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),

          // Alarm overlay
          if (_activeAlarm != null)
            AlarmOverlay(
              alarm: _activeAlarm!,
              onDismiss: () {
                AlarmService.instance.dismissAlarm();
                setState(() => _activeAlarm = null);
              },
              onDisableType: () async {
                final type = _activeAlarm!.type;
                final key = switch (type) {
                  AlarmType.water => 'water',
                  AlarmType.movement => 'movement',
                  AlarmType.bloodPressure => 'bp',
                };
                await StorageService.instance.setReminderEnabled(key, false);
                _initAlarms();
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa'),
                _buildNavItem(1, Icons.monitor_heart, Icons.monitor_heart_outlined, 'Tansiyon'),
                _buildNavItem(2, Icons.shield_rounded, Icons.shield_outlined, 'Risk'),
                _buildNavItem(3, Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'Bilgi'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryRed.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppTheme.primaryRed : AppTheme.textLight,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryRed : AppTheme.textLight,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
