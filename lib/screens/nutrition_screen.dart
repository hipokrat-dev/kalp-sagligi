import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/health_data.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _storage = StorageService.instance;
  List<NutritionEntry> _entries = [];
  int _calorieGoal = 2000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = await _storage.getNutritionEntries(DateTime.now());
    final goal = await _storage.getCalorieGoal();
    if (mounted) {
      setState(() {
        _entries = entries;
        _calorieGoal = goal;
      });
    }
  }

  int get _totalCalories => _entries.fold(0, (sum, e) => sum + e.calories);

  void _addEntry() async {
    final meals = ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Ara Öğün'];
    String selectedMeal = meals[0];
    final descController = TextEditingController();
    final calController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yemek Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedMeal,
                  decoration: const InputDecoration(labelText: 'Öğün'),
                  items: meals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => selectedMeal = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Yemek açıklaması',
                    hintText: 'Örn: Tavuk ızgara, salata',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: calController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kalori',
                    suffixText: 'kcal',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yaygın yemekler:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _quickMealChip('Çay', 2, descController, calController),
                    _quickMealChip('Kahve', 5, descController, calController),
                    _quickMealChip('Yumurta', 155, descController, calController),
                    _quickMealChip('Ekmek (1 dilim)', 80, descController, calController),
                    _quickMealChip('Pilav (1 porsiyon)', 200, descController, calController),
                    _quickMealChip('Tavuk (150g)', 250, descController, calController),
                    _quickMealChip('Salata', 100, descController, calController),
                    _quickMealChip('Çorba', 120, descController, calController),
                    _quickMealChip('Meyve', 80, descController, calController),
                    _quickMealChip('Yoğurt', 60, descController, calController),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final calories = int.tryParse(calController.text);
      if (calories != null && calories > 0) {
        await _storage.addNutritionEntry(
          DateTime.now(),
          NutritionEntry(
            date: DateTime.now(),
            meal: selectedMeal,
            description: descController.text.isEmpty ? selectedMeal : descController.text,
            calories: calories,
          ),
        );
        _loadData();
      }
    }
  }

  Widget _quickMealChip(String name, int cal, TextEditingController desc, TextEditingController calCtrl) {
    return ActionChip(
      label: Text('$name ($cal)', style: const TextStyle(fontSize: 11)),
      onPressed: () {
        desc.text = name;
        calCtrl.text = cal.toString();
      },
    );
  }

  void _editGoal() async {
    final controller = TextEditingController(text: _calorieGoal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günlük Kalori Hedefi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kalori hedefi',
            suffixText: 'kcal',
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
      setState(() => _calorieGoal = result);
      await _storage.setCalorieGoal(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalCalories / _calorieGoal).clamp(0.0, 1.5);
    final remaining = _calorieGoal - _totalCalories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beslenme Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _editGoal,
            tooltip: 'Hedef Ayarla',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Yemek Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bugün', style: TextStyle(color: Colors.grey)),
                          Text(
                            '$_totalCalories',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const Text('kcal', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            remaining >= 0 ? 'Kalan' : 'Fazla',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${remaining.abs()}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: remaining >= 0 ? Colors.green : AppTheme.primaryRed,
                            ),
                          ),
                          const Text('kcal', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(
                        _totalCalories > _calorieGoal ? AppTheme.primaryRed : Colors.green,
                      ),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hedef: $_calorieGoal kcal',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meal Entries
          if (_entries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'Henüz yemek eklenmedi',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const Text(
                      'Aşağıdaki butonu kullanarak yemek ekleyin',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_entries.length, (i) {
              final entry = _entries[i];
              final mealIcon = switch (entry.meal) {
                'Kahvaltı' => Icons.free_breakfast,
                'Öğle Yemeği' => Icons.lunch_dining,
                'Akşam Yemeği' => Icons.dinner_dining,
                _ => Icons.fastfood,
              };
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: Icon(mealIcon, color: Colors.green),
                  ),
                  title: Text(entry.description),
                  subtitle: Text(entry.meal),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.calories} kcal',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          await _storage.deleteNutritionEntry(DateTime.now(), i);
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
