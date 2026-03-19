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

class _WaterScreenState extends State<WaterScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService.instance;
  late AnimationController _animController;
  late Animation<double> _fillAnim;
  int _totalMl = 0;
  int _goalMl = 2500;
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fillAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _remainingMl => (_goalMl - _totalMl).clamp(0, 99999);
  double get _fillRatio => (_totalMl / _goalMl).clamp(0.0, 1.0);

  void _animateFill() {
    _fillAnim = Tween<double>(begin: _fillAnim.value, end: _fillRatio)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0);
  }

  Future<void> _loadData() async {
    final glasses = await _storage.getWaterGlasses(DateTime.now());
    final goalGlasses = await _storage.getWaterGoal();
    final enabled = await _storage.getReminderEnabled('water');
    if (mounted) {
      setState(() {
        _totalMl = glasses * 250;
        _goalMl = goalGlasses * 250;
        _remindersEnabled = enabled;
      });
      _animateFill();
    }
  }

  void _addWater(int ml) {
    setState(() => _totalMl += ml);
    _storage.setWaterGlasses(DateTime.now(), (_totalMl / 250).ceil());
    _animateFill();
  }

  void _removeWater() {
    if (_totalMl >= 200) {
      setState(() => _totalMl -= 200);
      _storage.setWaterGlasses(DateTime.now(), (_totalMl / 250).ceil());
      _animateFill();
    }
  }

  void _editGoal() async {
    final controller = TextEditingController(text: _goalMl.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Günlük Su Hedefi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: const InputDecoration(labelText: 'Hedef', suffixText: 'ml', prefixIcon: Icon(Icons.water_drop)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [1500, 2000, 2500, 3000, 3500].map((ml) => ActionChip(
                label: Text('$ml', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => controller.text = ml.toString(),
                backgroundColor: AppTheme.inputFill,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() => _goalMl = result);
      await _storage.setWaterGoal((result / 250).ceil());
      _animateFill();
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Su Ekle', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildAmountOption(ctx, 200, Icons.local_cafe_rounded, 'Bardak'),
                const SizedBox(width: 12),
                _buildAmountOption(ctx, 350, Icons.coffee_rounded, 'Şişe (küçük)'),
                const SizedBox(width: 12),
                _buildAmountOption(ctx, 500, Icons.water_drop_rounded, 'Şişe (büyük)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountOption(BuildContext ctx, int ml, IconData icon, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(ctx);
          _addWater(ml);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softShadow(const Color(0xFF42A5F5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text('$ml ml', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Su Takibi', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          GestureDetector(
            onTap: _editGoal,
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          // ── Hedef & Kalan ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Günlük Hedef', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$_goalMl ml', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.inputFill),
                Expanded(
                  child: Column(
                    children: [
                      Text('Kalan', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        _totalMl >= _goalMl ? 'Tamam!' : '$_remainingMl ml',
                        style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: _totalMl >= _goalMl ? Colors.green : const Color(0xFF42A5F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Su Bardağı + Butonlar ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Eksi butonu
              GestureDetector(
                onTap: _removeWater,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.remove_rounded, color: AppTheme.primaryRed, size: 28),
                ),
              ),
              const SizedBox(width: 24),

              // Animasyonlu su bardağı
              AnimatedBuilder(
                animation: _fillAnim,
                builder: (_, __) => CustomPaint(
                  size: const Size(120, 160),
                  painter: _WaterGlassPainter(fillRatio: _fillAnim.value),
                  child: SizedBox(
                    width: 120, height: 160,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_totalMl',
                              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          Text('ml', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Artı butonu
              GestureDetector(
                onTap: _showAddOptions,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)]),
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow(const Color(0xFF42A5F5)),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),

          if (_totalMl >= _goalMl)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.greenGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow(Colors.green),
                  ),
                  child: Text('Tebrikler! Hedefinize ulaştınız! 🎉',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ── Progress Bar ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUGÜNKÜ TÜKETİM',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _fillAnim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _fillAnim.value,
                      backgroundColor: const Color(0xFF42A5F5).withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF42A5F5)),
                      minHeight: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_totalMl ml', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF42A5F5))),
                    Text('$_goalMl ml', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textLight)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_fillRatio * 100).toStringAsFixed(0)}% tamamlandı',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Hatırlatıcılar ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_rounded, color: Color(0xFF42A5F5), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _remindersEnabled ? 'Hatırlatıcılar Açık' : 'Hatırlatıcılar Kapalı',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
                          ),
                          Text(
                            'Düzenli su içmeyi unutma',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _remindersEnabled,
                      activeColor: const Color(0xFF42A5F5),
                      onChanged: (v) async {
                        setState(() => _remindersEnabled = v);
                        await _storage.setReminderEnabled('water', v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule_rounded, size: 16, color: const Color(0xFF42A5F5)),
                            const SizedBox(width: 6),
                            Text('Zaman Ayarla', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF42A5F5), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 20, color: AppTheme.inputFill),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up_rounded, size: 16, color: const Color(0xFF42A5F5)),
                            const SizedBox(width: 6),
                            Text('Bildirim Sesi', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF42A5F5), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Water Glass Painter ──
class _WaterGlassPainter extends CustomPainter {
  final double fillRatio;
  _WaterGlassPainter({required this.fillRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = 16.0;
    final topWidth = w - inset;
    final bottomWidth = w * 0.65;
    final cornerRadius = 14.0;
    final glassTop = 10.0;
    final glassBottom = h - 10;
    final glassHeight = glassBottom - glassTop;

    // Glass outline path (trapezoid)
    final glassPath = Path();
    final topLeft = (w - topWidth) / 2;
    final topRight = topLeft + topWidth;
    final botLeft = (w - bottomWidth) / 2;
    final botRight = botLeft + bottomWidth;

    glassPath.moveTo(topLeft + cornerRadius, glassTop);
    glassPath.lineTo(topRight - cornerRadius, glassTop);
    glassPath.quadraticBezierTo(topRight, glassTop, topRight - 2, glassTop + cornerRadius);
    glassPath.lineTo(botRight + 2, glassBottom - cornerRadius);
    glassPath.quadraticBezierTo(botRight, glassBottom, botRight - cornerRadius, glassBottom);
    glassPath.lineTo(botLeft + cornerRadius, glassBottom);
    glassPath.quadraticBezierTo(botLeft, glassBottom, botLeft + 2, glassBottom - cornerRadius);
    glassPath.lineTo(topLeft + 2, glassTop + cornerRadius);
    glassPath.quadraticBezierTo(topLeft, glassTop, topLeft + cornerRadius, glassTop);
    glassPath.close();

    // Glass background
    final bgPaint = Paint()..color = const Color(0xFFF0F4FF);
    canvas.drawPath(glassPath, bgPaint);

    // Water fill
    if (fillRatio > 0) {
      final waterTop = glassBottom - (glassHeight * fillRatio.clamp(0.0, 1.0));
      final waterLeftAtTop = topLeft + (botLeft - topLeft) * ((waterTop - glassTop) / glassHeight);
      final waterRightAtTop = topRight + (botRight - topRight) * ((waterTop - glassTop) / glassHeight);

      final waterPath = Path();
      // Wavy top
      waterPath.moveTo(waterLeftAtTop + 4, waterTop);
      final waveW = (waterRightAtTop - waterLeftAtTop) / 3;
      waterPath.quadraticBezierTo(waterLeftAtTop + waveW, waterTop - 4, waterLeftAtTop + waveW * 1.5, waterTop);
      waterPath.quadraticBezierTo(waterLeftAtTop + waveW * 2, waterTop + 4, waterLeftAtTop + waveW * 2.5, waterTop);
      waterPath.lineTo(waterRightAtTop - 4, waterTop);
      // Right side
      waterPath.lineTo(botRight - 2, glassBottom - cornerRadius);
      waterPath.quadraticBezierTo(botRight, glassBottom, botRight - cornerRadius, glassBottom);
      // Bottom
      waterPath.lineTo(botLeft + cornerRadius, glassBottom);
      waterPath.quadraticBezierTo(botLeft, glassBottom, botLeft + 2, glassBottom - cornerRadius);
      // Left side
      waterPath.lineTo(waterLeftAtTop + 4, waterTop);
      waterPath.close();

      // Clip to glass
      canvas.save();
      canvas.clipPath(glassPath);

      // Blue gradient based on fill
      final blueIntensity = (0.3 + fillRatio * 0.7).clamp(0.0, 1.0);
      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFBBDEFB), const Color(0xFF42A5F5), blueIntensity)!,
            Color.lerp(const Color(0xFF90CAF9), const Color(0xFF1E88E5), blueIntensity)!,
          ],
        ).createShader(Rect.fromLTWH(0, waterTop, w, glassBottom - waterTop));

      canvas.drawPath(waterPath, waterPaint);
      canvas.restore();
    }

    // Glass border
    final borderPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(glassPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter old) => old.fillRatio != fillRatio;
}
