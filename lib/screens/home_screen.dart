import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/heartbeat_animation.dart';
import 'steps_screen.dart';
import 'water_screen.dart';
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
  DateTime? _smokingQuitDate;
  bool _notificationsEnabled = false;
  double _height = 0;
  double _weight = 0;
  double _targetWeight = 0;

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
    final quitDate = await _storage.getSmokingQuitDate();
    final riskData = await _storage.getRiskChecklist();
    final targetWeight = await _storage.getTargetWeight();

    if (mounted) {
      setState(() {
        _steps = steps;
        _stepGoal = stepGoal;
        _waterGlasses = water;
        _waterGoal = waterGoal;
        _smokingQuitDate = quitDate;
        _height = (riskData['height'] ?? 0.0).toDouble();
        _weight = (riskData['weight'] ?? 0.0).toDouble();
        _targetWeight = targetWeight;
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

  void _showWeightDialog() async {
    final hCtrl = TextEditingController(text: _height > 0 ? _height.toStringAsFixed(0) : '');
    final wCtrl = TextEditingController(text: _weight > 0 ? _weight.toStringAsFixed(0) : '');
    final tCtrl = TextEditingController(text: _targetWeight > 0 ? _targetWeight.toStringAsFixed(0) : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('VKİ & Kilo Hedefi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Boy', suffixText: 'cm', prefixIcon: Icon(Icons.height)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mevcut Kilo', suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hedef Kilo', suffixText: 'kg', prefixIcon: Icon(Icons.flag_rounded)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade400, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sağlıklı kilo verme hızı haftada 0.5-1 kg\'dır.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      final t = double.tryParse(tCtrl.text) ?? 0;

      if (h > 0 && w > 0) {
        setState(() {
          _height = h;
          _weight = w;
          _targetWeight = t;
        });
        final rd = await _storage.getRiskChecklist();
        rd['height'] = h;
        rd['weight'] = w;
        await _storage.saveRiskChecklist(rd);
        if (t > 0) await _storage.setTargetWeight(t);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                // ── Grid Cards (2x2) ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                  children: [
                    // Adımlar
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB74D)]),
                      icon: Icons.directions_walk_rounded,
                      title: 'Adımlar',
                      value: _formatNumber(_steps),
                      subtitle: '/ $_stepGoal hedef',
                      progress: _steps / _stepGoal,
                      onTap: () => _navigateAndRefresh(const StepsScreen()),
                    ),
                    // Su
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)]),
                      icon: Icons.water_drop_rounded,
                      title: 'Su',
                      value: '$_waterGlasses',
                      subtitle: '/ $_waterGoal bardak',
                      progress: _waterGlasses / _waterGoal,
                      onTap: () => _navigateAndRefresh(const WaterScreen()),
                    ),
                    // Sigara
                    _GridCard(
                      gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF80CBC4)]),
                      icon: Icons.smoke_free_rounded,
                      title: 'Sigara',
                      value: smokingDays != null ? '$smokingDays' : '—',
                      subtitle: smokingDays != null ? 'gün sigarasız' : 'Başla',
                      progress: smokingDays != null ? (smokingDays / 365).clamp(0.0, 1.0) : 0.0,
                      onTap: () => _navigateAndRefresh(const SmokingScreen()),
                    ),
                    // VKİ & Kilo Hedefi
                    _BmiWeightCard(
                      bmi: _bmi,
                      bmiLabel: _bmiLabel,
                      bmiColor: _bmiColor,
                      weight: _weight,
                      targetWeight: _targetWeight,
                      onTap: _showWeightDialog,
                    ),
                  ],
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
                Flexible(
                  child: Text(widget.value,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
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
              builder: (_, child) => ClipRRect(
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

// ── VKİ & Kilo Hedefi Kare Kartı ──

class _BmiWeightCard extends StatelessWidget {
  final double bmi;
  final String bmiLabel;
  final Color bmiColor;
  final double weight;
  final double targetWeight;
  final VoidCallback onTap;

  const _BmiWeightCard({
    required this.bmi,
    required this.bmiLabel,
    required this.bmiColor,
    required this.weight,
    required this.targetWeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = bmi > 0;
    final hasTarget = targetWeight > 0 && weight > 0;
    final toGo = hasTarget ? (weight - targetWeight) : 0.0;
    final progress = (hasTarget && toGo > 0) ? (1.0 - toGo / (weight * 0.3)).clamp(0.0, 1.0) : (hasTarget ? 1.0 : 0.0);

    final gradientColors = hasData
        ? [bmiColor, bmiColor.withValues(alpha: 0.65)]
        : [const Color(0xFF78909C), const Color(0xFFB0BEC5)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow(gradientColors.first),
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
              child: const Icon(Icons.monitor_weight_rounded, color: Colors.white, size: 20),
            ),
            const Spacer(),
            if (hasData) ...[
              Row(
                children: [
                  Text('VKİ ',
                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(bmiLabel,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(bmi.toStringAsFixed(1),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      hasTarget
                          ? (toGo > 0 ? '-${toGo.toStringAsFixed(1)} kg' : 'Hedefe ulaştın!')
                          : '${weight.toStringAsFixed(0)} kg',
                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hasTarget ? progress : 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 5,
                ),
              ),
              if (hasTarget)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'Hedef: ${targetWeight.toStringAsFixed(0)} kg',
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 9),
                  ),
                ),
            ] else ...[
              Text('VKİ & Kilo',
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Hesapla',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  minHeight: 5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
