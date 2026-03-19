import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService.instance;
  final _repaintKey = GlobalKey();
  late AnimationController _scoreAnim;
  late Animation<double> _scoreValue;

  int _steps = 0, _stepGoal = 10000;
  int _waterMl = 0, _waterGoalMl = 2500;
  int? _mood, _sleepQuality;
  double _sleepHours = 0, _weight = 0, _targetWeight = 0, _height = 0;
  String? _lastBpText, _bpStatus;
  Color _bpColor = Colors.grey;
  int _dailyScore = 0;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreValue = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOutCubic));
    _loadData();
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final steps = await _storage.getSteps(now);
    final stepGoal = await _storage.getStepGoal();
    final waterGlasses = await _storage.getWaterGlasses(now);
    final waterGoal = await _storage.getWaterGoal();
    final mood = await _storage.getMood(now);
    final sleep = await _storage.getSleep(now);
    final risk = await _storage.getRiskChecklist();
    final target = await _storage.getTargetWeight();
    final bpRecords = await _storage.getBloodPressureRecords();

    String? bpText;
    String? bpSt;
    Color bpC = Colors.grey;
    if (bpRecords.isNotEmpty) {
      final r = bpRecords.first;
      final today = DateTime(now.year, now.month, now.day);
      if (r.date.isAfter(today)) {
        bpText = '${r.systolic}/${r.diastolic} mmHg  •  ${r.pulse} bpm';
        bpSt = r.riskLevel;
        bpC = switch (r.riskLevel) {
          'Normal' => const Color(0xFF4CAF50),
          'Normal Ustu' => const Color(0xFFFFC107),
          'Yukselmis' => const Color(0xFFFF9800),
          'Yuksek' => const Color(0xFFE53935),
          'Kriz' => const Color(0xFFB71C1C),
          _ => Colors.grey,
        };
      }
    }

    // Calculate score
    int score = 0;
    // Steps (30 pts)
    score += ((steps / stepGoal).clamp(0.0, 1.0) * 30).toInt();
    // Water (20 pts)
    score += ((waterGlasses / waterGoal).clamp(0.0, 1.0) * 20).toInt();
    // Sleep (20 pts)
    if (sleep != null) {
      final h = (sleep['hours'] as num?)?.toDouble() ?? 0;
      final q = (sleep['quality'] as int?) ?? 2;
      score += ((h / 8).clamp(0.0, 1.0) * 10).toInt();
      score += ((q / 4) * 10).toInt();
    }
    // Mood (10 pts)
    if (mood != null) score += ((mood / 4) * 10).toInt();
    // BP (20 pts)
    if (bpSt != null) {
      score += switch (bpSt) {
        'Normal' => 20,
        'Normal Ustu' => 14,
        'Yukselmis' => 8,
        _ => 0,
      };
    }

    if (mounted) {
      setState(() {
        _steps = steps;
        _stepGoal = stepGoal;
        _waterMl = waterGlasses * 250;
        _waterGoalMl = waterGoal * 250;
        _mood = mood;
        _sleepQuality = sleep?['quality'] as int?;
        _sleepHours = (sleep?['hours'] as num?)?.toDouble() ?? 0;
        _weight = (risk['weight'] as num?)?.toDouble() ?? 0;
        _height = (risk['height'] as num?)?.toDouble() ?? 0;
        _targetWeight = target;
        _lastBpText = bpText;
        _bpStatus = bpSt;
        _bpColor = bpC;
        _dailyScore = score.clamp(0, 100);
      });
      _scoreValue = Tween<double>(begin: 0, end: _dailyScore / 100).animate(
          CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOutCubic));
      _scoreAnim.forward(from: 0);
    }
  }

  Color get _scoreColor {
    if (_dailyScore >= 80) return const Color(0xFF4CAF50);
    if (_dailyScore >= 50) return const Color(0xFFFF9800);
    return AppTheme.primaryRed;
  }

  String get _scoreLabel {
    if (_dailyScore >= 80) return 'Harika Gün!';
    if (_dailyScore >= 50) return 'İyi Gidiyorsun';
    return 'Daha İyisini Yapabilirsin';
  }

  static const _moodEmojis = ['😢', '😟', '😐', '😊', '😍'];
  static const _moodLabels = ['Kötü', 'Düşük', 'Normal', 'İyi', 'Harika'];
  static const _sleepEmojis = ['😴', '😞', '😐', '😊', '🌟'];
  static const _sleepLabels = ['Çok Kötü', 'Kötü', 'Orta', 'İyi', 'Mükemmel'];

  Future<void> _shareReport() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gunluk_rapor.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Kalp Sağlığı - Günlük Raporum');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Paylaşım hatası: $e'),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final dayName = weekDays[now.weekday - 1];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.darkRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text('Günlük Rapor', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('$dayName, $dateStr', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: AppTheme.background,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    // ── Score Gauge ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Text('GÜNLÜK SAĞLIK SKORU', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 160, height: 160,
                            child: AnimatedBuilder(
                              animation: _scoreValue,
                              builder: (_, __) => CustomPaint(
                                painter: _ScoreGaugePainter(
                                  progress: _scoreValue.value,
                                  color: _scoreColor,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$_dailyScore',
                                          style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, color: _scoreColor)),
                                      Text(_scoreLabel,
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _scoreColor)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 2x2 Grid ──
                    Row(
                      children: [
                        Expanded(child: _buildMiniCard(
                          Icons.directions_walk_rounded, const Color(0xFFFF9800),
                          'Adım', '$_steps', '/ $_stepGoal  •  ${((_steps / _stepGoal) * 100).toStringAsFixed(0)}%',
                          (_steps / _stepGoal).clamp(0.0, 1.0),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMiniCard(
                          Icons.water_drop_rounded, const Color(0xFF42A5F5),
                          'Su', '$_waterMl ml', '/ $_waterGoalMl ml  •  ${(_waterMl / 250).toInt()} bardak',
                          (_waterMl / _waterGoalMl).clamp(0.0, 1.0),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildMiniCard(
                          Icons.bedtime_rounded, const Color(0xFF5C6BC0),
                          'Uyku',
                          _sleepQuality != null ? '${_sleepHours.toStringAsFixed(1)} sa' : '—',
                          _sleepQuality != null ? '${_sleepEmojis[_sleepQuality!]} ${_sleepLabels[_sleepQuality!]}' : 'Kayıt yok',
                          (_sleepHours / 8).clamp(0.0, 1.0),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMiniCard(
                          Icons.monitor_weight_rounded, const Color(0xFF26A69A),
                          'Kilo',
                          _weight > 0 ? '${_weight.toStringAsFixed(0)} kg' : '—',
                          _targetWeight > 0 && _weight > 0
                              ? 'Hedef: ${_targetWeight.toStringAsFixed(0)} kg  (${(_weight - _targetWeight) > 0 ? '-' : '+'}${(_weight - _targetWeight).abs().toStringAsFixed(1)})'
                              : 'Hedef girilmedi',
                          0,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Kan Basıncı ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _bpColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.monitor_heart_rounded, color: _bpColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kan Basıncı', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                                Text(
                                  _lastBpText ?? 'Bugün ölçüm yok',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                          if (_bpStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _bpColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_bpStatus!, style: GoogleFonts.inter(color: _bpColor, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Mood ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(_mood != null ? _moodEmojis[_mood!] : '😐', style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Günlük Mod', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                                Text(
                                  _mood != null ? _moodLabels[_mood!] : 'Kayıt yok',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Share Button ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _shareReport,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFC0392B), Color(0xFFE74C3C)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Raporu Paylaş', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(IconData icon, Color color, String title, String value, String subtitle, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (progress > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScoreGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0.8 * math.pi, 1.4 * math.pi, false, bgPaint);

    // Foreground arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0.8 * math.pi, 1.4 * math.pi * progress, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter old) => old.progress != progress || old.color != color;
}
