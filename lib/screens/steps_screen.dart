import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/health_connect_service.dart';
import '../services/alarm_service.dart';
import 'reminder_settings_screen.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final _storage = StorageService.instance;
  final _controller = TextEditingController();
  int _steps = 0;
  int _goal = 10000;
  Map<String, int> _history = {};
  bool _healthConnectEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final steps = await _storage.getSteps(DateTime.now());
    final goal = await _storage.getStepGoal();
    final history = await _storage.getStepsHistory(7);
    final hcEnabled = await _storage.getHealthConnectEnabled();

    if (mounted) {
      setState(() {
        _steps = steps;
        _goal = goal;
        _history = history;
        _healthConnectEnabled = hcEnabled;
      });
    }

    // Try to sync from Health Connect
    if (hcEnabled) _syncHealthConnect();
  }

  Future<void> _syncHealthConnect() async {
    try {
      final hcSteps = await HealthConnectService.instance.getTodaySteps();
      if (hcSteps > _steps && mounted) {
        setState(() => _steps = hcSteps);
        await _storage.setSteps(DateTime.now(), hcSteps);
        final history = await _storage.getStepsHistory(7);
        if (mounted) setState(() => _history = history);
      }
    } catch (_) {}
  }

  void _addSteps() {
    final value = int.tryParse(_controller.text);
    if (value == null || value <= 0) return;
    setState(() => _steps += value);
    _storage.setSteps(DateTime.now(), _steps);
    _controller.clear();
    AlarmService.instance.reportSteps(_steps);
    AlarmService.instance.reportActivity();
  }

  void _setSteps() async {
    final controller = TextEditingController(text: _steps.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adım Sayısını Güncelle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Toplam adım',
            suffixText: 'adım',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != null && result >= 0) {
      setState(() => _steps = result);
      await _storage.setSteps(DateTime.now(), result);
      _loadData();
    }
  }

  void _editGoal() async {
    final controller = TextEditingController(text: _goal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günlük Adım Hedefi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef adım',
            suffixText: 'adım',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() => _goal = result);
      await _storage.setStepGoal(result);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps / _goal).clamp(0.0, 1.0);
    final calories = (_steps * 0.04).toInt();
    final km = (_steps * 0.0007).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adım Takibi'),
        actions: [
          if (_healthConnectEnabled)
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: () async {
                await _syncHealthConnect();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Health Connect ile senkronize edildi'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              tooltip: 'Health Connect Senkronize',
            ),
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
            tooltip: 'Hareket Hatırlatma Ayarları',
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _editGoal,
            tooltip: 'Hedef Ayarla',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Circular Progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: progress,
                        color: Colors.orange,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_walk, size: 32, color: Colors.orange),
                            Text(
                              '$_steps',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Hedef: $_goal',
                              style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(Icons.local_fire_department, '$calories kcal', 'Kalori'),
                      _buildStat(Icons.straighten, '$km km', 'Mesafe'),
                      _buildStat(Icons.timer, '${(_steps / 100).toInt()} dk', 'Süre'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Add Steps
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adım Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Adım sayısı',
                            prefixIcon: Icon(Icons.add),
                          ),
                          onSubmitted: (_) => _addSteps(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addSteps,
                        child: const Text('Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [1000, 2000, 5000].map((v) {
                      return ActionChip(
                        label: Text('+$v'),
                        onPressed: () {
                          setState(() => _steps += v);
                          _storage.setSteps(DateTime.now(), _steps);
                          _loadData();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: _setSteps,
                      icon: const Icon(Icons.edit),
                      label: const Text('Manuel Güncelle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Weekly History
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Haftalık Geçmiş', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _history.entries.toList().reversed.map((entry) {
                        final ratio = _goal > 0 ? (entry.value / _goal).clamp(0.0, 1.0) : 0.0;
                        final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        final date = DateTime.parse(entry.key);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(entry.value / 1000).toStringAsFixed(1)}k',
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 28,
                              height: 80 * ratio,
                              decoration: BoxDecoration(
                                color: ratio >= 1.0 ? Colors.orange : Colors.orange.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              days[date.weekday - 1],
                              style: TextStyle(fontSize: 11, color: AppTheme.textLight),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
