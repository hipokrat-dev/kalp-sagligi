import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/health_tips.dart';
import '../services/notification_service.dart';
import '../widgets/heartbeat_animation.dart';
import 'steps_screen.dart';
import 'water_screen.dart';
import 'nutrition_screen.dart';
import 'smoking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService.instance;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
      _fadeController.forward(from: 0);
    }
  }

  double get _bmi {
    if (_height <= 0 || _weight <= 0) return 0;
    final h = _height / 100;
    return _weight / (h * h);
  }

  String get _bmiLabel {
    if (_bmi <= 0) return '—';
    if (_bmi < 18.5) return 'Zayıf';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Kilolu';
    return 'Obez';
  }

  Color get _bmiColor {
    if (_bmi <= 0) return AppTheme.textLight;
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadData();
  }

  void _showBmiDialog() async {
    final hCtrl = TextEditingController(text: _height > 0 ? _height.toStringAsFixed(0) : '');
    final wCtrl = TextEditingController(text: _weight > 0 ? _weight.toStringAsFixed(0) : '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('VKİ Hesapla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: hCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Boy', suffixText: 'cm', prefixIcon: Icon(Icons.height))),
            const SizedBox(height: 12),
            TextField(controller: wCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kilo', suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (result == true) {
      final h = double.tryParse(hCtrl.text) ?? 0;
      final w = double.tryParse(wCtrl.text) ?? 0;
      if (h > 0 && w > 0) {
        setState(() { _height = h; _weight = w; });
        final rd = await _storage.getRiskChecklist();
        rd['height'] = h;
        rd['weight'] = w;
        await _storage.saveRiskChecklist(rd);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = HealthTips.getDailyTip();
    final smokingDays = _smokingQuitDate != null ? DateTime.now().difference(_smokingQuitDate!).inDays : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryRed,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                // ── Header ──
                Row(
                  children: [
                    PulseRing(
                      size: 48,
                      child: const HeartbeatAnimation(size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kalp Sağlığı',
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          Text('Bugün nasıl hissediyorsun?',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                    _buildHeaderIcon(
                      _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                      onTap: _toggleNotifications,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Daily Tip Card ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text('Günün Bilgisi',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(tip['title']!,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(tip['body']!,
                          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Grid Cards ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                  children: [
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB74D)]),
                      icon: Icons.directions_walk_rounded,
                      title: 'Adımlar',
                      value: _formatNumber(_steps),
                      subtitle: '/ $_stepGoal hedef',
                      progress: _steps / _stepGoal,
                      onTap: () => _navigateAndRefresh(const StepsScreen()),
                    ),
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)]),
                      icon: Icons.water_drop_rounded,
                      title: 'Su',
                      value: '$_waterGlasses',
                      subtitle: '/ $_waterGoal bardak',
                      progress: _waterGlasses / _waterGoal,
                      onTap: () => _navigateAndRefresh(const WaterScreen()),
                    ),
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)]),
                      icon: Icons.restaurant_rounded,
                      title: 'Kalori',
                      value: _formatNumber(_totalCalories),
                      subtitle: '/ $_calorieGoal kcal',
                      progress: _totalCalories / _calorieGoal,
                      onTap: () => _navigateAndRefresh(const NutritionScreen()),
                    ),
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF80CBC4)]),
                      icon: Icons.smoke_free_rounded,
                      title: 'Sigara',
                      value: smokingDays != null ? '$smokingDays' : '—',
                      subtitle: smokingDays != null ? 'gün sigarasız' : 'Başla',
                      progress: smokingDays != null ? (smokingDays / 365).clamp(0.0, 1.0) : 0.0,
                      onTap: () => _navigateAndRefresh(const SmokingScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── VKİ Card ──
                GestureDetector(
                  onTap: _showBmiDialog,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_bmiColor, _bmiColor.withValues(alpha: 0.5)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.monitor_weight_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VKİ Hesaplama',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              if (_bmi > 0) ...[
                                Row(
                                  children: [
                                    Text(_bmi.toStringAsFixed(1),
                                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: _bmiColor)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _bmiColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_bmiLabel,
                                          style: TextStyle(color: _bmiColor, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _BmiBar(bmi: _bmi),
                              ] else
                                Text('Dokunarak boy ve kilo girin',
                                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppTheme.textLight.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildHeaderIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, color: AppTheme.textDark, size: 20),
      ),
    );
  }
}

// ── Grid Card ──

class _GridCard extends StatefulWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final VoidCallback onTap;

  const _GridCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _progressAnim = Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic));
    _progressController.forward();
  }

  @override
  void didUpdateWidget(_GridCard old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _progressAnim = Tween<double>(begin: _progressAnim.value, end: widget.progress.clamp(0.0, 1.0))
          .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic));
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow(widget.gradient.colors.first),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(widget.title,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.value,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(widget.subtitle,
                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressAnim.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BMI Bar ──

class _BmiBar extends StatelessWidget {
  final double bmi;
  const _BmiBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            _seg(Colors.blue, bmi < 18.5),
            const SizedBox(width: 2),
            _seg(Colors.green, bmi >= 18.5 && bmi < 25),
            const SizedBox(width: 2),
            _seg(Colors.orange, bmi >= 25 && bmi < 30),
            const SizedBox(width: 2),
            _seg(AppTheme.primaryRed, bmi >= 30),
          ],
        ),
      ),
    );
  }

  Widget _seg(Color c, bool active) =>
      Expanded(child: Container(decoration: BoxDecoration(
        color: active ? c : c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      )));
}
