import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService.instance;
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  bool _familyHistory = false;
  bool _smoking = false;
  bool _hypertension = false;
  bool _hyperlipidemia = false;
  bool _diabetes = false;
  bool _inactivity = false;
  double _height = 0.0;
  double _weight = 0.0;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _animateScore() {
    _progressAnim = Tween<double>(begin: _progressAnim.value, end: _riskScore / 100).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0);
  }

  Future<void> _loadData() async {
    final data = await _storage.getRiskChecklist();
    if (mounted) {
      setState(() {
        _familyHistory = data['familyHistory'] ?? false;
        _smoking = data['smoking'] ?? false;
        _hypertension = data['hypertension'] ?? false;
        _hyperlipidemia = data['hyperlipidemia'] ?? false;
        _diabetes = data['diabetes'] ?? false;
        _inactivity = data['inactivity'] ?? false;
        _height = (data['height'] ?? 0.0).toDouble();
        _weight = (data['weight'] ?? 0.0).toDouble();
        _heightController.text = _height > 0 ? _height.toStringAsFixed(0) : '';
        _weightController.text = _weight > 0 ? _weight.toStringAsFixed(0) : '';
      });
      _animateScore();
    }
  }

  Future<void> _saveData() async {
    await _storage.saveRiskChecklist({
      'familyHistory': _familyHistory,
      'smoking': _smoking,
      'hypertension': _hypertension,
      'hyperlipidemia': _hyperlipidemia,
      'diabetes': _diabetes,
      'inactivity': _inactivity,
      'height': _height,
      'weight': _weight,
    });
    _animateScore();
  }

  double get _bmi {
    if (_height <= 0 || _weight <= 0) return 0;
    final heightM = _height / 100;
    return _weight / (heightM * heightM);
  }

  String get _bmiCategory {
    if (_bmi <= 0) return 'Hesaplanamadi';
    if (_bmi < 18.5) return 'Zayif';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Fazla Kilolu';
    if (_bmi < 35) return 'Obez (Sinif I)';
    if (_bmi < 40) return 'Obez (Sinif II)';
    return 'Morbid Obez';
  }

  Color get _bmiColor {
    if (_bmi <= 0) return Colors.grey;
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return AppTheme.primaryRed;
  }

  int get _riskScore {
    int score = 0;
    if (_familyHistory) score += 20;
    if (_smoking) score += 20;
    if (_hypertension) score += 15;
    if (_hyperlipidemia) score += 15;
    if (_diabetes) score += 15;
    if (_inactivity) score += 10;
    if (_bmi >= 30) {
      score += 15;
    } else if (_bmi >= 25) {
      score += 8;
    } else if (_bmi > 0 && _bmi < 18.5) {
      score += 5;
    }
    return score.clamp(0, 100);
  }

  String get _riskLevel {
    if (_riskScore >= 60) return 'Yuksek Risk';
    if (_riskScore >= 35) return 'Orta Risk';
    if (_riskScore > 0) return 'Dusuk Risk';
    return 'Degerlendirilmedi';
  }

  Color get _riskColor {
    if (_riskScore >= 60) return AppTheme.primaryRed;
    if (_riskScore >= 35) return Colors.orange;
    if (_riskScore > 0) return Colors.green;
    return Colors.grey;
  }

  List<Color> get _riskGradientColors {
    if (_riskScore >= 60) return const [Color(0xFFE53935), Color(0xFFFF6B6B)];
    if (_riskScore >= 35) return const [Color(0xFFFF9800), Color(0xFFFFB74D)];
    if (_riskScore > 0) return const [Color(0xFF66BB6A), Color(0xFFA5D6A7)];
    return [Colors.grey, Colors.grey.shade300];
  }

  int get _checkedCount {
    int count = 0;
    if (_familyHistory) count++;
    if (_smoking) count++;
    if (_hypertension) count++;
    if (_hyperlipidemia) count++;
    if (_diabetes) count++;
    if (_inactivity) count++;
    if (_bmi >= 25) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Kalp Riski Degerlendirmesi', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Risk Score Card with gradient ring
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text('KALP HASTALIGI RISK SKORU', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 170,
                  height: 170,
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _GradientRingPainter(
                        progress: _progressAnim.value,
                        gradientColors: _riskGradientColors,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_riskScore',
                              style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, color: _riskColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _riskColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _riskLevel,
                                style: GoogleFonts.inter(color: _riskColor, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$_checkedCount / 7 risk faktoru tespit edildi',
                  style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Risk Checklist
          Text('RISK FAKTORLERI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

          _buildCheckItem(
            icon: Icons.family_restroom_rounded,
            title: 'Aile Oykusu',
            subtitle: 'Ailede erken yasta kalp hastaligi (erkek <55, kadin <65 yas)',
            value: _familyHistory,
            riskPoints: 20,
            onChanged: (v) { setState(() => _familyHistory = v); _saveData(); },
          ),
          _buildCheckItem(
            icon: Icons.smoking_rooms_rounded,
            title: 'Sigara Kullanimi',
            subtitle: 'Aktif sigara kullaniyorum veya son 5 yilda biraktim',
            value: _smoking,
            riskPoints: 20,
            onChanged: (v) { setState(() => _smoking = v); _saveData(); },
          ),
          _buildCheckItem(
            icon: Icons.monitor_heart_rounded,
            title: 'Hipertansiyon',
            subtitle: 'Yuksek tansiyon tanisi var veya ilac kullaniyorum',
            value: _hypertension,
            riskPoints: 15,
            onChanged: (v) { setState(() => _hypertension = v); _saveData(); },
          ),
          _buildCheckItem(
            icon: Icons.bloodtype_rounded,
            title: 'Hiperlipidemi',
            subtitle: 'Yuksek kolesterol / trigliserit tanisi var',
            value: _hyperlipidemia,
            riskPoints: 15,
            onChanged: (v) { setState(() => _hyperlipidemia = v); _saveData(); },
          ),
          _buildCheckItem(
            icon: Icons.water_drop_rounded,
            title: 'Diyabet',
            subtitle: 'Tip 1 veya Tip 2 diyabet tanisi var',
            value: _diabetes,
            riskPoints: 15,
            onChanged: (v) { setState(() => _diabetes = v); _saveData(); },
          ),
          _buildCheckItem(
            icon: Icons.weekend_rounded,
            title: 'Hareketsizlik',
            subtitle: 'Haftada 150 dakikadan az egzersiz yapiyorum',
            value: _inactivity,
            riskPoints: 10,
            onChanged: (v) { setState(() => _inactivity = v); _saveData(); },
          ),

          const SizedBox(height: 20),

          // BMI Calculator
          Text('BOY / KILO / VKI HESAPLAMA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

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
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Boy',
                          suffixText: 'cm',
                          prefixIcon: Icon(Icons.height_rounded),
                        ),
                        onChanged: (v) {
                          setState(() => _height = double.tryParse(v) ?? 0);
                          _saveData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Kilo',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.monitor_weight_rounded),
                        ),
                        onChanged: (v) {
                          setState(() => _weight = double.tryParse(v) ?? 0);
                          _saveData();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_bmi > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _bmiColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('Vucut Kitle Indeksi (VKI)', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          _bmi.toStringAsFixed(1),
                          style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: _bmiColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: _bmiColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _bmiCategory,
                            style: GoogleFonts.inter(color: _bmiColor, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        if (_bmi >= 25) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: _bmiColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Risk skora +${_bmi >= 30 ? 15 : 8} puan eklendi',
                                style: GoogleFonts.inter(fontSize: 12, color: _bmiColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // BMI gradient bar
                  Row(
                    children: [
                      _buildBmiRange('Zayif', '<18.5', Colors.blue),
                      _buildBmiRange('Normal', '18.5-25', Colors.green),
                      _buildBmiRange('Fazla', '25-30', Colors.orange),
                      _buildBmiRange('Obez', '>30', AppTheme.primaryRed),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Doctor Warning
          if (_riskScore > 0)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(
                  color: _riskScore >= 35
                      ? AppTheme.primaryRed.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: _riskScore >= 35
                              ? AppTheme.primaryGradient2
                              : AppTheme.orangeGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _riskScore >= 35 ? Icons.warning_rounded : Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _riskScore >= 60
                              ? 'Acil Doktor Gorusmesi Onerilir!'
                              : _riskScore >= 35
                                  ? 'Doktorunuzla Gorusmeniz Onerilir'
                                  : 'Duzenli Kontrol Onerisi',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _riskScore >= 35 ? AppTheme.primaryRed : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getDoctorAdvice(),
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu degerlendirme tibbi teshis yerine gecmez. '
                            'Risklerinizle ilgili mutlaka bir kardiyoloji uzmanina danisin.',
                            style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Risk Factor Details
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
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.primaryGradient2.createShader(bounds),
                      child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text('Risk Faktorleri Hakkinda', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow('Aile Oykusu',
                    'Birinci derece akrabalarinizda erken yasta koroner arter hastaligi oykusu riski 2 kat artirir.'),
                _buildInfoRow('Sigara',
                    'Sigara, damar sertligini hizlandirir ve kalp krizi riskini 2-4 kat artirir.'),
                _buildInfoRow('Hipertansiyon',
                    'Kontrolsuz yuksek tansiyon kalp yetmezligi, inme ve bobrek hasarina yol acabilir.'),
                _buildInfoRow('Hiperlipidemi',
                    'Yuksek LDL kolesterol damarlarda plak birikimine neden olarak damar tikanikligina yol acar.'),
                _buildInfoRow('Diyabet',
                    'Diyabet damar yapisini bozar, kalp hastaligi riskini 2-4 kat artirir.'),
                _buildInfoRow('Hareketsizlik',
                    'Duzenli egzersiz yapmamak kardiyovaskuler hastalik riskini onemli olcude artirir.'),
                _buildInfoRow('Obezite (VKI)',
                    'VKI 25 uzeri kalp hastaligi, hipertansiyon ve diyabet riskini artirir.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getDoctorAdvice() {
    final risks = <String>[];
    if (_familyHistory) risks.add('aile oykusu');
    if (_smoking) risks.add('sigara kullanimi');
    if (_hypertension) risks.add('hipertansiyon');
    if (_hyperlipidemia) risks.add('hiperlipidemi');
    if (_diabetes) risks.add('diyabet');
    if (_inactivity) risks.add('hareketsizlik');
    if (_bmi >= 25) risks.add('yuksek VKI (${_bmi.toStringAsFixed(1)})');

    if (_riskScore >= 60) {
      return 'Toplam $_checkedCount risk faktorunuz tespit edildi: '
          '${risks.join(", ")}. '
          'Bu risk profili ile en kisa surede bir kardiyoloji uzmanina basvurmaniz '
          've kapsamli bir kalp sagligi degerlendirmesi yaptirmaniz siddetle onerilir.';
    } else if (_riskScore >= 35) {
      return 'Tespit edilen risk faktorleriniz: ${risks.join(", ")}. '
          'Bu risklerin yonetimi icin doktorunuzla goruserek kisisel bir '
          'tedavi ve yasam tarzi plani olusturmaniz onerilir.';
    } else {
      return 'Tespit edilen risk faktorleriniz: ${risks.join(", ")}. '
          'Risk seviyeniz dusuk olsa da duzenli saglik kontrolleri yaptirmaya devam edin.';
    }
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required int riskPoints,
    required ValueChanged<bool> onChanged,
  }) {
    final accentColor = value ? AppTheme.primaryRed : AppTheme.textLight;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
        border: value ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppTheme.primaryRed.withValues(alpha: 0.4),
          activeThumbColor: AppTheme.primaryRed,
          inactiveTrackColor: AppTheme.inputFill,
          secondary: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
              ),
              if (value)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$riskPoints',
                    style: GoogleFonts.inter(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        ),
      ),
    );
  }

  Widget _buildBmiRange(String label, String range, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          Text(range, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textDark, height: 1.4, fontWeight: FontWeight.w400),
                children: [
                  TextSpan(text: '$title: ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _GradientRingPainter({required this.progress, required this.gradientColors});

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
