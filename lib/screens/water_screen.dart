import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _storage = StorageService.instance;
  int _glasses = 0;
  int _goal = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final glasses = await _storage.getWaterGlasses(DateTime.now());
    final goal = await _storage.getWaterGoal();
    if (mounted) {
      setState(() {
        _glasses = glasses;
        _goal = goal;
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
    final controller = TextEditingController(text: _goal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günlük Su Hedefi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Bardak sayısı',
            suffixText: 'bardak',
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
      await _storage.setWaterGoal(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_glasses / _goal).clamp(0.0, 1.0);
    final ml = _glasses * 250;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Takibi'),
        actions: [
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
                            Icon(
                              Icons.water_drop,
                              size: 40,
                              color: Colors.blue.shade400,
                            ),
                            Text(
                              '$_glasses/$_goal',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'bardak',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$ml ml / ${_goal * 250} ml',
                      style: TextStyle(fontSize: 16, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 4),
                    if (_glasses >= _goal)
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
                      const Text(
                        'Bugünkü Su Tüketimin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
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
                                size: 28,
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
