import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../services/friends_service.dart';
import '../services/challenge_service.dart';
import '../services/auth_service.dart';
import '../widgets/alarm_overlay.dart';
import 'home_screen.dart';
import 'daily_report_screen.dart';
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
  StreamSubscription? _friendRequestSub;
  StreamSubscription? _challengeCountSub;
  int _pendingFriendRequests = 0;
  int _activeChallengeCount = 0;

  final _screens = const [
    HomeScreen(),
    DailyReportScreen(),
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
    _listenToFriendRequests();
    _listenToChallengeCount();
    _checkExpiredChallenges();
  }

  void _listenToFriendRequests() {
    _friendRequestSub = FriendsService.instance.pendingRequestCountStream().listen((count) {
      if (mounted) setState(() => _pendingFriendRequests = count);
    });
  }

  void _listenToChallengeCount() {
    _challengeCountSub = ChallengeService.instance.activeChallengeCountStream().listen((count) {
      if (mounted) setState(() => _activeChallengeCount = count);
    });
  }

  Future<void> _checkExpiredChallenges() async {
    try {
      final results = await ChallengeService.instance.checkAndCompleteExpiredChallenges();
      final currentUid = AuthService.instance.currentUserId;

      for (final result in results) {
        if (result.winnerUid == currentUid && mounted) {
          _triggerWinnerAlarm(result.title);
        }
      }
    } catch (_) {}
  }

  void _triggerWinnerAlarm(String challengeTitle) {
    // Show a trophy dialog for the winner
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F3C6}', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                'Tebrikler!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$challengeTitle" challenge\'ini kazandiniz!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Harika!'),
              ),
            ),
          ],
        ),
      );
    }
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
    _friendRequestSub?.cancel();
    _challengeCountSub?.cancel();
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
                _buildNavItem(1, Icons.assessment_rounded, Icons.assessment_outlined, 'Rapor'),
                _buildNavItem(2, Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'Bilgi'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {int badgeCount = 0}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryRed.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppTheme.primaryRed : AppTheme.textLight,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
