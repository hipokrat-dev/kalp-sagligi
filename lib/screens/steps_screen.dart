import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
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

class _StepsScreenState extends State<StepsScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService.instance;
  final _controller = TextEditingController();
  late AnimationController _progressController;
  late Animation<double> _progressAnim;
  int _steps = 0;
  int _goal = 10000;
  Map<String, int> _history = {};
  bool _healthConnectEnabled = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _animateProgress() {
    final target = (_steps / _goal).clamp(0.0, 1.0);
    _progressAnim = Tween<double>(begin: _progressAnim.value, end: target).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward(from: 0);
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
      _animateProgress();
    }

    if (hcEnabled) _syncHealthConnect();
  }

  Future<void> _syncHealthConnect() async {
    try {
      final hcSteps = await HealthConnectService.instance.getTodaySteps();
      if (hcSteps > _steps && mounted) {
        setState(() => _steps = hcSteps);
        await _storage.setSteps(DateTime.now(), hcSteps);
        final history = await _storage.getStepsHistory(7);
        if (mounted) {
          setState(() => _history = history);
          _animateProgress();
        }
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
    _animateProgress();
  }

  void _setSteps() async {
    final controller = TextEditingController(text: _steps.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Adim Sayisini Guncelle', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Toplam adim',
            suffixText: 'adim',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Gunluk Adim Hedefi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef adim',
            suffixText: 'adim',
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
      setState(() => _goal = result);
      await _storage.setStepGoal(result);
      _animateProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = (_steps * 0.04).toInt();
    final km = (_steps * 0.0007).toStringAsFixed(1);
    final minutes = (_steps / 100).toInt();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Adim Takibi', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        actions: [
          if (_healthConnectEnabled)
            _buildHeaderAction(Icons.sync_rounded, () async {
              await _syncHealthConnect();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Health Connect ile senkronize edildi', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }),
          _buildHeaderAction(Icons.notifications_active_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()));
          }),
          const SizedBox(width: 8),
          _buildHeaderAction(Icons.flag_rounded, _editGoal),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Circular Progress Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _GradientCirclePainter(
                        progress: _progressAnim.value,
                        gradientColors: const [Color(0xFFFF9800), Color(0xFFFFB74D)],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                              ).createShader(bounds),
                              child: const Icon(Icons.directions_walk_rounded, size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_steps',
                              style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                            ),
                            Text(
                              '/ $_goal hedef',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row as mini gradient cards
                Row(
                  children: [
                    _buildStatCard(Icons.local_fire_department_rounded, '$calories', 'kcal', const [Color(0xFFE53935), Color(0xFFFF6B6B)]),
                    const SizedBox(width: 10),
                    _buildStatCard(Icons.straighten_rounded, km, 'km', const [Color(0xFF42A5F5), Color(0xFF90CAF9)]),
                    const SizedBox(width: 10),
                    _buildStatCard(Icons.timer_rounded, '$minutes', 'dk', const [Color(0xFF26A69A), Color(0xFF80CBC4)]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add Steps Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ADIM EKLE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Adim sayisi',
                          prefixIcon: const Icon(Icons.add_rounded),
                          filled: true,
                          fillColor: AppTheme.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.inputRadius), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _addSteps(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addSteps,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.orangeGradient,
                          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                          boxShadow: AppTheme.softShadow(const Color(0xFFFF9800)),
                        ),
                        child: Center(
                          child: Text('Ekle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [1000, 2000, 5000].map((v) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _steps += v);
                          _storage.setSteps(DateTime.now(), _steps);
                          _animateProgress();
                          _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+$v',
                            style: GoogleFonts.inter(color: const Color(0xFFFF9800), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _setSteps,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text('Manuel Guncelle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Weekly History
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HAFTALIK GECMIS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _history.entries.toList().reversed.map((entry) {
                      final ratio = _goal > 0 ? (entry.value / _goal).clamp(0.0, 1.0) : 0.0;
                      final days = ['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'];
                      final date = DateTime.parse(entry.key);
                      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(entry.value / 1000).toStringAsFixed(1)}k',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 90 * ratio + 4,
                            decoration: BoxDecoration(
                              gradient: ratio >= 1.0
                                  ? AppTheme.orangeGradient
                                  : LinearGradient(
                                      colors: [
                                        const Color(0xFFFF9800).withValues(alpha: 0.4),
                                        const Color(0xFFFFB74D).withValues(alpha: 0.4),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            days[date.weekday - 1],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday ? const Color(0xFFFF9800) : AppTheme.textLight,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Icon(icon, color: AppTheme.textDark, size: 18),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String unit, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(unit, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _GradientCirclePainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _GradientCirclePainter({required this.progress, required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final bgPaint = Paint()
      ..color = gradientColors.first.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: gradientColors,
      );

      final fgPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
