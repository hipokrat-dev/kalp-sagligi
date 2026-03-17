import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'reminder_settings_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _storage = StorageService.instance;
  int _glasses = 0;
  int _goalMl = 3500;
  final int _glassSize = 250; // ml per glass

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int get _goal => (_goalMl / _glassSize).ceil();
  int get _currentMl => _glasses * _glassSize;

  Future<void> _loadData() async {
    final glasses = await _storage.getWaterGlasses(DateTime.now());
    final goal = await _storage.getWaterGoal();
    if (mounted) {
      setState(() {
        _glasses = glasses;
        _goalMl = goal * _glassSize; // backward compat: stored as glasses
      });
    }
  }

  void _addGlass() {
    setState(() => _glasses++);
    _storage.setWaterGlasses(DateTime.now(), _glasses);
  }

  void _removeGlass() {
    if (_glasses > 0) {
      setState(() => _glasses--);
      _storage.setWaterGlasses(DateTime.now(), _glasses);
    }
  }

  void _editGoal() async {
    final controller = TextEditingController(text: _goalMl.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Günlük Su Hedefi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hedef',
                suffixText: 'ml',
                prefixIcon: Icon(Icons.water_drop),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [2000, 2500, 3000, 3500, 4000].map((ml) {
                return ActionChip(
                  label: Text('$ml ml'),
                  onPressed: () => controller.text = ml.toString(),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Önerilen: Günde 2000-3500 ml',
              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
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
      final glasses = (result / _glassSize).ceil();
      setState(() => _goalMl = result);
      await _storage.setWaterGoal(glasses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_glasses / _goal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
            tooltip: 'Su Hatırlatma Ayarları',
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _editGoal,
            tooltip: 'Hedef Ayarla',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Water Level Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 14,
                            backgroundColor: Colors.blue.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation(Colors.blue),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            Icon(Icons.water_drop, size: 40, color: Colors.blue.shade400),
                            Text('$_currentMl',
                                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800)),
                            Text('/ $_goalMl ml',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_glasses bardak  •  ${(_goalMl - _currentMl).clamp(0, 99999)} ml kaldı',
                      style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 4),
                    if (_currentMl >= _goalMl)
                      const Text(
                        'Tebrikler! Günlük hedefinize ulaştınız!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add/Remove Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'remove',
                  onPressed: _removeGlass,
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: AppTheme.textDark,
                  mini: true,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 24),
                FloatingActionButton.large(
                  heroTag: 'add',
                  onPressed: _addGlass,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.water_drop, size: 36),
                ),
                const SizedBox(width: 24),
                FloatingActionButton(
                  heroTag: 'reset',
                  onPressed: () {
                    setState(() => _glasses = 0);
                    _storage.setWaterGlasses(DateTime.now(), 0);
                  },
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: AppTheme.textDark,
                  mini: true,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Glass indicators
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bugünkü Su Tüketimin',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _goal,
                          itemBuilder: (context, index) {
                            final filled = index < _glasses;
                            return Container(
                              decoration: BoxDecoration(
                                color: filled ? Colors.blue.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: filled ? Colors.blue : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.water_drop,
                                color: filled ? Colors.blue : Colors.grey.shade300,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
