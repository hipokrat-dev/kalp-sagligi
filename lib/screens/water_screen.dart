import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'reminder_settings_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService.instance;
  late AnimationController _progressController;
  late Animation<double> _progressAnim;
  int _glasses = 0;
  int _goalMl = 3500;
  final int _glassSize = 250;

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
    _progressController.dispose();
    super.dispose();
  }

  int get _goal => (_goalMl / _glassSize).ceil();
  int get _currentMl => _glasses * _glassSize;

  void _animateProgress() {
    final target = (_glasses / _goal).clamp(0.0, 1.0);
    _progressAnim = Tween<double>(begin: _progressAnim.value, end: target).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward(from: 0);
  }

  Future<void> _loadData() async {
    final glasses = await _storage.getWaterGlasses(DateTime.now());
    final goal = await _storage.getWaterGoal();
    if (mounted) {
      setState(() {
        _glasses = glasses;
        _goalMl = goal * _glassSize;
      });
      _animateProgress();
    }
  }

  void _addGlass() {
    setState(() => _glasses++);
    _storage.setWaterGlasses(DateTime.now(), _glasses);
    _animateProgress();
  }

  void _removeGlass() {
    if (_glasses > 0) {
      setState(() => _glasses--);
      _storage.setWaterGlasses(DateTime.now(), _glasses);
      _animateProgress();
    }
  }

  void _editGoal() async {
    final controller = TextEditingController(text: _goalMl.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Gunluk Su Hedefi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
                  label: Text('$ml ml', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                  onPressed: () => controller.text = ml.toString(),
                  backgroundColor: AppTheme.inputFill,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Onerilen: Gunde 2000-3500 ml',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      final glasses = (result / _glassSize).ceil();
      setState(() => _goalMl = result);
      await _storage.setWaterGoal(glasses);
      _animateProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Su Takibi', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        actions: [
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
                        gradientColors: const [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                              ).createShader(bounds),
                              child: const Icon(Icons.water_drop_rounded, size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_currentMl',
                              style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                            ),
                            Text(
                              '/ $_goalMl ml',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_glasses bardak  -  ${(_goalMl - _currentMl).clamp(0, 99999)} ml kaldi',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textLight),
                ),
                if (_currentMl >= _goalMl) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.greenGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tebrikler! Gunluk hedefinize ulastiniz!',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick-add pills
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
                Text('HIZLI EKLE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickPill(
                        icon: Icons.remove_rounded,
                        label: 'Cikar',
                        colors: [Colors.grey.shade400, Colors.grey.shade300],
                        onTap: _removeGlass,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildQuickPill(
                        icon: Icons.water_drop_rounded,
                        label: '+250 ml',
                        colors: const [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                        onTap: _addGlass,
                        large: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickPill(
                        icon: Icons.refresh_rounded,
                        label: 'Sifirla',
                        colors: [Colors.grey.shade400, Colors.grey.shade300],
                        onTap: () {
                          setState(() => _glasses = 0);
                          _storage.setWaterGlasses(DateTime.now(), 0);
                          _animateProgress();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Glass grid
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
                Text('BUGUNKU SU TUKETIMIN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _goal,
                  itemBuilder: (context, index) {
                    final filled = index < _glasses;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        gradient: filled
                            ? const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: filled ? null : const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: filled ? Colors.white : Colors.grey.shade300,
                        size: 24,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
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
    );
  }

  Widget _buildQuickPill({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
    bool large = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: large ? 16 : 12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: large ? 24 : 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: large ? 13 : 11, fontWeight: FontWeight.w600),
            ),
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
