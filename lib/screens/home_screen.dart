import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/health_tips.dart';
import '../services/notification_service.dart';
import 'steps_screen.dart';
import 'water_screen.dart';
import 'nutrition_screen.dart';
import 'smoking_screen.dart';
import 'blood_pressure_screen.dart';
import 'risk_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  int _steps = 0;
  int _stepGoal = 10000;
  int _waterGlasses = 0;
  int _waterGoal = 8;
  int _totalCalories = 0;
  int _calorieGoal = 2000;
  DateTime? _smokingQuitDate;
  bool _notificationsEnabled = false;
  double _height = 0;
  double _weight = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final steps = await _storage.getSteps(now);
    final stepGoal = await _storage.getStepGoal();
    final water = await _storage.getWaterGlasses(now);
    final waterGoal = await _storage.getWaterGoal();
    final entries = await _storage.getNutritionEntries(now);
    final calorieGoal = await _storage.getCalorieGoal();
    final quitDate = await _storage.getSmokingQuitDate();
    final riskData = await _storage.getRiskChecklist();

    if (mounted) {
      setState(() {
        _steps = steps;
        _stepGoal = stepGoal;
        _waterGlasses = water;
        _waterGoal = waterGoal;
        _totalCalories = entries.fold(0, (sum, e) => sum + e.calories);
        _calorieGoal = calorieGoal;
        _smokingQuitDate = quitDate;
        _height = (riskData['height'] ?? 0.0).toDouble();
        _weight = (riskData['weight'] ?? 0.0).toDouble();
      });
    }
  }

  double get _bmi {
    if (_height <= 0 || _weight <= 0) return 0;
    final h = _height / 100;
    return _weight / (h * h);
  }

  String get _bmiLabel {
    if (_bmi <= 0) return 'Hesapla';
    if (_bmi < 18.5) return 'Zayıf';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  Color get _bmiColor {
    if (_bmi <= 0) return Colors.grey;
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return AppTheme.primaryRed;
  }

  void _toggleNotifications() async {
    if (_notificationsEnabled) {
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.scheduleWaterReminder();
    }
    setState(() => _notificationsEnabled = !_notificationsEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_notificationsEnabled ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadData();
  }

  void _showBmiDialog() async {
    final heightCtrl = TextEditingController(text: _height > 0 ? _height.toStringAsFixed(0) : '');
    final weightCtrl = TextEditingController(text: _weight > 0 ? _weight.toStringAsFixed(0) : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('VKİ Hesapla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Boy',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilo',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );

    if (result == true) {
      final h = double.tryParse(heightCtrl.text) ?? 0;
      final w = double.tryParse(weightCtrl.text) ?? 0;
      if (h > 0 && w > 0) {
        setState(() {
          _height = h;
          _weight = w;
        });
        final riskData = await _storage.getRiskChecklist();
        riskData['height'] = h;
        riskData['weight'] = w;
        await _storage.saveRiskChecklist(riskData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = HealthTips.getDailyTip();
    final smokingDays = _smokingQuitDate != null
        ? DateTime.now().difference(_smokingQuitDate!).inDays
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 24),
            SizedBox(width: 8),
            Text('Kalp Sağlığı'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_notificationsEnabled ? Icons.notifications_active : Icons.notifications_off_outlined),
            onPressed: _toggleNotifications,
            tooltip: 'Bildirimler',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateAndRefresh(const SettingsScreen()),
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryRed,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Günün Sağlık Bilgisi ──
            Card(
              color: AppTheme.darkRed,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text('Günün Sağlık Bilgisi',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(tip['title']!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(tip['body']!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Adım Takibi ──
            _buildTrackerCard(
              icon: Icons.directions_walk,
              title: 'Adım Takibi',
              value: '$_steps',
              unit: 'adım',
              subtitle: 'Hedef: $_stepGoal',
              progress: _steps / _stepGoal,
              color: Colors.orange,
              onTap: () => _navigateAndRefresh(const StepsScreen()),
            ),

            // ── Su Takibi ──
            _buildTrackerCard(
              icon: Icons.water_drop,
              title: 'Su Takibi',
              value: '$_waterGlasses',
              unit: 'bardak',
              subtitle: 'Hedef: $_waterGoal bardak  •  ${_waterGlasses * 250} ml',
              progress: _waterGlasses / _waterGoal,
              color: Colors.blue,
              onTap: () => _navigateAndRefresh(const WaterScreen()),
            ),

            // ── Kalori Takibi ──
            _buildTrackerCard(
              icon: Icons.restaurant,
              title: 'Beslenme / Kalori',
              value: '$_totalCalories',
              unit: 'kcal',
              subtitle: 'Hedef: $_calorieGoal kcal  •  Kalan: ${(_calorieGoal - _totalCalories).clamp(0, 99999)}',
              progress: _totalCalories / _calorieGoal,
              color: Colors.green,
              onTap: () => _navigateAndRefresh(const NutritionScreen()),
            ),

            // ── Sigara Bırakma ──
            _buildTrackerCard(
              icon: Icons.smoke_free,
              title: 'Sigara Bırakma',
              value: smokingDays != null ? '$smokingDays' : '—',
              unit: smokingDays != null ? 'gün sigarasız' : '',
              subtitle: smokingDays != null
                  ? 'Başlangıç: ${_smokingQuitDate!.day}/${_smokingQuitDate!.month}/${_smokingQuitDate!.year}'
                  : 'Sayacı başlatmak için dokunun',
              progress: smokingDays != null ? (smokingDays / 365).clamp(0.0, 1.0) : 0.0,
              color: Colors.teal,
              onTap: () => _navigateAndRefresh(const SmokingScreen()),
            ),

            // ── VKİ Hesaplama ──
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _showBmiDialog,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _bmiColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.monitor_weight, color: _bmiColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VKİ Hesaplama',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            if (_bmi > 0) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _bmi.toStringAsFixed(1),
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _bmiColor),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('kg/m²', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // BMI bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: [
                                      Expanded(flex: 185, child: Container(color: Colors.blue.withValues(alpha: _bmi < 18.5 ? 1 : 0.2))),
                                      const SizedBox(width: 2),
                                      Expanded(flex: 65, child: Container(color: Colors.green.withValues(alpha: _bmi >= 18.5 && _bmi < 25 ? 1 : 0.2))),
                                      const SizedBox(width: 2),
                                      Expanded(flex: 50, child: Container(color: Colors.orange.withValues(alpha: _bmi >= 25 && _bmi < 30 ? 1 : 0.2))),
                                      const SizedBox(width: 2),
                                      Expanded(flex: 50, child: Container(color: AppTheme.primaryRed.withValues(alpha: _bmi >= 30 ? 1 : 0.2))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _bmiColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_bmiLabel,
                                        style: TextStyle(color: _bmiColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  Text('${_height.toStringAsFixed(0)} cm  •  ${_weight.toStringAsFixed(0)} kg',
                                      style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                                ],
                              ),
                            ] else ...[
                              Text(
                                'Boy ve kilonuzu girerek VKİ hesaplayın',
                                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dokunarak hesapla',
                                style: TextStyle(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _bmiColor.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tansiyon & Nabız ──
            _buildMenuCard(
              icon: Icons.monitor_heart,
              title: 'Tansiyon & Nabız',
              subtitle: 'Tansiyon ve nabız değerlerini kaydet ve takip et',
              color: AppTheme.primaryRed,
              onTap: () => _navigateAndRefresh(const BloodPressureScreen()),
            ),

            // ── Risk Değerlendirmesi ──
            _buildMenuCard(
              icon: Icons.health_and_safety,
              title: 'Risk Değerlendirmesi',
              subtitle: 'Kalp sağlığı risk göstergelerini görüntüle',
              color: AppTheme.darkRed,
              onTap: () => _navigateAndRefresh(const RiskScreen()),
            ),

            // ── Bilgilendirme ──
            _buildMenuCard(
              icon: Icons.menu_book,
              title: 'Bilgilendirme',
              subtitle: 'Tansiyon, hareket, ölçüler ve sigara bırakma rehberi',
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required double progress,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(value,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(unit, style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
