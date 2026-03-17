import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final meals = ['Kahvalti', 'Ogle Yemegi', 'Aksam Yemegi', 'Ara Ogun'];
    String selectedMeal = meals[0];
    final descController = TextEditingController();
    final calController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
          title: Text('Yemek Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedMeal,
                  decoration: const InputDecoration(labelText: 'Ogun'),
                  items: meals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => selectedMeal = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Yemek aciklamasi',
                    hintText: 'Orn: Tavuk izgara, salata',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: calController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Kalori',
                    suffixText: 'kcal',
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('YAYGIN YEMEKLER', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textLight, letterSpacing: 1)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _quickMealPill('Cay', 2, descController, calController),
                    _quickMealPill('Kahve', 5, descController, calController),
                    _quickMealPill('Yumurta', 155, descController, calController),
                    _quickMealPill('Ekmek', 80, descController, calController),
                    _quickMealPill('Pilav', 200, descController, calController),
                    _quickMealPill('Tavuk', 250, descController, calController),
                    _quickMealPill('Salata', 100, descController, calController),
                    _quickMealPill('Corba', 120, descController, calController),
                    _quickMealPill('Meyve', 80, descController, calController),
                    _quickMealPill('Yogurt', 60, descController, calController),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  Widget _quickMealPill(String name, int cal, TextEditingController desc, TextEditingController calCtrl) {
    return GestureDetector(
      onTap: () {
        desc.text = name;
        calCtrl.text = cal.toString();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$name ($cal)',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
        ),
      ),
    );
  }

  void _editGoal() async {
    final controller = TextEditingController(text: _calorieGoal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Gunluk Kalori Hedefi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            labelText: 'Kalori hedefi',
            suffixText: 'kcal',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() => _calorieGoal = result);
      await _storage.setCalorieGoal(result);
    }
  }

  Color _mealAccentColor(String meal) {
    return switch (meal) {
      'Kahvalti' => const Color(0xFFFF9800),
      'Ogle Yemegi' => const Color(0xFF42A5F5),
      'Aksam Yemegi' => const Color(0xFF7E57C2),
      _ => const Color(0xFF26A69A),
    };
  }

  IconData _mealIcon(String meal) {
    return switch (meal) {
      'Kahvalti' => Icons.free_breakfast_rounded,
      'Ogle Yemegi' => Icons.lunch_dining_rounded,
      'Aksam Yemegi' => Icons.dinner_dining_rounded,
      _ => Icons.fastfood_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _calorieGoal - _totalCalories;
    final progress = (_totalCalories / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Beslenme Takibi', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        actions: [
          GestureDetector(
            onTap: _editGoal,
            child: Container(
              width: 40, height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.flag_rounded, color: AppTheme.textDark, size: 18),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _addEntry,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: AppTheme.greenGradient,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            boxShadow: AppTheme.softShadow(const Color(0xFF66BB6A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Yemek Ekle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BUGUN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalCalories',
                          style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                        ),
                        Text('kcal', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          remaining >= 0 ? 'KALAN' : 'FAZLA',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${remaining.abs()}',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: remaining >= 0 ? Colors.green : AppTheme.primaryRed,
                          ),
                        ),
                        Text('kcal', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      _totalCalories > _calorieGoal ? AppTheme.primaryRed : Colors.green,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hedef: $_calorieGoal kcal',
                  style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Meal Entries
          if (_entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.restaurant_menu_rounded, size: 32, color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Henuz yemek eklenmedi',
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Asagidaki butonu kullanarak yemek ekleyin',
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_entries.length, (i) {
              final entry = _entries[i];
              final accentColor = _mealAccentColor(entry.meal);
              final icon = _mealIcon(entry.meal);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    // Colored left accent
                    Container(
                      width: 4,
                      height: 70,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          bottomLeft: Radius.circular(22),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.description, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                                  const SizedBox(height: 2),
                                  Text(entry.meal, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Text(
                              '${entry.calories}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
                            ),
                            Text(' kcal', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                await _storage.deleteNutritionEntry(DateTime.now(), i);
                                _loadData();
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.textLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
