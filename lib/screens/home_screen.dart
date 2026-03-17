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

    if (mounted) {
      setState(() {
        _steps = steps;
        _stepGoal = stepGoal;
        _waterGlasses = water;
        _waterGoal = waterGoal;
        _totalCalories = entries.fold(0, (sum, e) => sum + e.calories);
        _calorieGoal = calorieGoal;
        _smokingQuitDate = quitDate;
      });
    }
  }

  void _toggleNotifications() async {
    if (_notificationsEnabled) {
      await NotificationService.instance.cancelAll();
    } else {
      await NotificationService.instance.scheduleWaterReminder();
    }
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_notificationsEnabled
              ? 'Bildirimler açıldı'
              : 'Bildirimler kapatıldı'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadData();
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
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
            ),
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
            // Daily Health Tip Card
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
                        Text(
                          'Günün Sağlık Bilgisi',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip['title']!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['body']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildQuickCard(
                  icon: Icons.directions_walk,
                  title: 'Adımlar',
                  value: '$_steps',
                  subtitle: 'Hedef: $_stepGoal',
                  progress: _steps / _stepGoal,
                  color: Colors.orange,
                  onTap: () => _navigateAndRefresh(const StepsScreen()),
                ),
                _buildQuickCard(
                  icon: Icons.water_drop,
                  title: 'Su',
                  value: '$_waterGlasses bardak',
                  subtitle: 'Hedef: $_waterGoal',
                  progress: _waterGlasses / _waterGoal,
                  color: Colors.blue,
                  onTap: () => _navigateAndRefresh(const WaterScreen()),
                ),
                _buildQuickCard(
                  icon: Icons.restaurant,
                  title: 'Kalori',
                  value: '$_totalCalories',
                  subtitle: 'Hedef: $_calorieGoal kcal',
                  progress: _totalCalories / _calorieGoal,
                  color: Colors.green,
                  onTap: () => _navigateAndRefresh(const NutritionScreen()),
                ),
                _buildQuickCard(
                  icon: Icons.smoke_free,
                  title: 'Sigara',
                  value: smokingDays != null ? '$smokingDays gün' : 'Başla',
                  subtitle: smokingDays != null ? 'sigarasız' : 'Sayacı başlat',
                  progress: smokingDays != null
                      ? (smokingDays / 365).clamp(0.0, 1.0)
                      : 0.0,
                  color: Colors.teal,
                  onTap: () => _navigateAndRefresh(const SmokingScreen()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Menu Cards
            _buildMenuCard(
              icon: Icons.monitor_heart,
              title: 'Tansiyon & Nabız',
              subtitle: 'Tansiyon ve nabız değerlerini kaydet ve takip et',
              color: AppTheme.primaryRed,
              onTap: () => _navigateAndRefresh(const BloodPressureScreen()),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              icon: Icons.health_and_safety,
              title: 'Risk Değerlendirmesi',
              subtitle: 'Kalp sağlığı risk göstergelerini görüntüle',
              color: AppTheme.darkRed,
              onTap: () => _navigateAndRefresh(const RiskScreen()),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              icon: Icons.menu_book,
              title: 'Bilgilendirme',
              subtitle: 'Tansiyon, hareket, ölçüler ve sigara bırakma rehberi',
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InfoScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: AppTheme.textLight, fontSize: 11),
              ),
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
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: color),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
