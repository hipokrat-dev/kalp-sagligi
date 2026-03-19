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
  late AnimationController _animCtrl;
  late Animation<double> _scoreAnim;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // Checklist items
  bool _regularExercise = false;
  bool _balancedDiet = false;
  bool _smoking = false;
  bool _alcohol = false;
  int _stressLevel = 0; // 0=Düşük, 1=Orta, 2=Yüksek
  bool _goodSleep = false;
  bool _regularCheckup = false;
  // Medical risks
  bool _familyHistory = false;
  bool _hypertension = false;
  bool _diabetes = false;
  bool _hyperlipidemia = false;
  // Medication
  bool _hypertensionMed = false;
  bool _diabetesMed = false;
  bool _hyperlipidemiaMed = false;

  double _height = 0, _weight = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _loadData();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await _storage.getRiskChecklist();
    if (mounted) {
      setState(() {
        _familyHistory = data['familyHistory'] ?? false;
        _hypertension = data['hypertension'] ?? false;
        _diabetes = data['diabetes'] ?? false;
        _hyperlipidemia = data['hyperlipidemia'] ?? false;
        _hypertensionMed = data['hypertensionMed'] ?? false;
        _diabetesMed = data['diabetesMed'] ?? false;
        _hyperlipidemiaMed = data['hyperlipidemiaMed'] ?? false;
        _smoking = data['smoking'] ?? false;
        _regularExercise = !(data['inactivity'] ?? true);
        _balancedDiet = data['balancedDiet'] ?? false;
        _alcohol = data['alcohol'] ?? false;
        _stressLevel = data['stressLevel'] ?? 0;
        _goodSleep = data['goodSleep'] ?? false;
        _regularCheckup = data['regularCheckup'] ?? false;
        _height = (data['height'] ?? 0.0).toDouble();
        _weight = (data['weight'] ?? 0.0).toDouble();
        _heightCtrl.text = _height > 0 ? _height.toStringAsFixed(0) : '';
        _weightCtrl.text = _weight > 0 ? _weight.toStringAsFixed(0) : '';
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
      'hypertensionMed': _hypertensionMed,
      'diabetesMed': _diabetesMed,
      'hyperlipidemiaMed': _hyperlipidemiaMed,
      'inactivity': !_regularExercise,
      'balancedDiet': _balancedDiet,
      'alcohol': _alcohol,
      'stressLevel': _stressLevel,
      'goodSleep': _goodSleep,
      'regularCheckup': _regularCheckup,
      'height': _height,
      'weight': _weight,
    });
    _animateScore();
  }

  void _animateScore() {
    _scoreAnim = Tween<double>(begin: _scoreAnim.value, end: _riskScore / 100).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward(from: 0);
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
    if (_bmi <= 0) return Colors.grey;
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return AppTheme.primaryRed;
  }

  int get _riskScore {
    int score = 0;
    // Medical risks (negative - increase score)
    if (_familyHistory) score += 15;
    if (_hypertension) score += 12;
    if (_diabetes) score += 12;
    if (_hyperlipidemia) score += 10;
    if (_smoking) score += 15;
    if (_alcohol) score += 5;
    if (!_regularExercise) score += 10;
    if (!_balancedDiet) score += 5;
    if (_stressLevel == 1) score += 3;
    if (_stressLevel == 2) score += 8;
    if (!_goodSleep) score += 5;
    if (!_regularCheckup) score += 3;
    // BMI
    if (_bmi >= 30) score += 12;
    else if (_bmi >= 25) score += 6;
    return score.clamp(0, 100);
  }

  String get _riskLevel {
    if (_riskScore >= 50) return 'Yüksek Risk';
    if (_riskScore >= 25) return 'Orta Risk';
    if (_riskScore > 0) return 'Düşük Risk';
    return 'Değerlendirilmedi';
  }

  Color get _riskColor {
    if (_riskScore >= 50) return AppTheme.primaryRed;
    if (_riskScore >= 25) return const Color(0xFFFF9800);
    if (_riskScore > 0) return const Color(0xFF4CAF50);
    return Colors.grey;
  }

  int get _positiveCount {
    int c = 0;
    if (_regularExercise) c++;
    if (_balancedDiet) c++;
    if (!_smoking) c++;
    if (!_alcohol) c++;
    if (_stressLevel == 0) c++;
    if (_goodSleep) c++;
    if (_regularCheckup) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.darkRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Risk Skoru', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          // ── Score Gauge ──
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
                  width: 180, height: 180,
                  child: AnimatedBuilder(
                    animation: _scoreAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _RiskGaugePainter(progress: _scoreAnim.value, color: _riskColor),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$_riskScore', style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: _riskColor)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: _riskColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(_riskLevel, style: GoogleFonts.inter(color: _riskColor, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('$_positiveCount / 7 sağlıklı alışkanlık',
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── VKİ ──
          Text('VÜCUt KİTLE İNDEKSİ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.cardRadius), boxShadow: AppTheme.cardShadow),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: _heightCtrl, keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Boy', suffixText: 'cm', prefixIcon: Icon(Icons.height_rounded)),
                      onChanged: (v) { setState(() => _height = double.tryParse(v) ?? 0); _saveData(); },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: _weightCtrl, keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(labelText: 'Kilo', suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight_rounded)),
                      onChanged: (v) { setState(() => _weight = double.tryParse(v) ?? 0); _saveData(); },
                    )),
                  ],
                ),
                if (_bmi > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_bmi.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: _bmiColor)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: _bmiColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(_bmiLabel, style: GoogleFonts.inter(color: _bmiColor, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildBmiBar(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Health Checklist ──
          Text('SAĞLIK KONTROL LİSTESİ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

          _checkItem(Icons.directions_run_rounded, const Color(0xFFFF9800), 'Düzenli Egzersiz', 'Haftada en az 150 dk orta şiddetli', _regularExercise,
              (v) { setState(() => _regularExercise = v); _saveData(); }),
          _checkItem(Icons.restaurant_rounded, const Color(0xFF4CAF50), 'Dengeli Beslenme', 'Sebze, meyve ağırlıklı beslenme', _balancedDiet,
              (v) { setState(() => _balancedDiet = v); _saveData(); }),
          _checkItem(Icons.smoking_rooms_rounded, const Color(0xFFE53935), 'Sigara İçiyorum', 'Sigara kalp hastalığı riskini 2-4x artırır', _smoking,
              (v) { setState(() => _smoking = v); _saveData(); }),
          _checkItem(Icons.local_bar_rounded, const Color(0xFF7E57C2), 'Alkol İçiyorum', 'Alkol kan basıncını yükseltir', _alcohol,
              (v) { setState(() => _alcohol = v); _saveData(); }),
          // Stres seviyesi
          _buildStressSelector(),
          _checkItem(Icons.bedtime_rounded, const Color(0xFF5C6BC0), 'Kaliteli Uyku', 'Her gece 7-8 saat uyku', _goodSleep,
              (v) { setState(() => _goodSleep = v); _saveData(); }),
          _checkItem(Icons.medical_services_rounded, const Color(0xFFE53935), 'Düzenli Check-up', 'Yılda en az 1 kez sağlık kontrolü', _regularCheckup,
              (v) { setState(() => _regularCheckup = v); _saveData(); }),

          const SizedBox(height: 20),

          // ── Medical Risks ──
          Text('TIBBİ RİSK FAKTÖRLERİ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

          _riskItem(Icons.family_restroom_rounded, 'Aile Öyküsü', 'Ailede erken yaşta kalp hastalığı', _familyHistory, null,
              (v) { setState(() => _familyHistory = v); _saveData(); }, null),
          _riskItemWithMed(Icons.monitor_heart_rounded, 'Yüksek Tansiyon', 'Tansiyon değerleri normalin üstünde', _hypertension, _hypertensionMed,
              (v) { setState(() => _hypertension = v); if (!v) setState(() => _hypertensionMed = false); _saveData(); },
              (v) { setState(() => _hypertensionMed = v); _saveData(); }),
          _riskItemWithMed(Icons.water_drop_rounded, 'Yüksek Şeker', 'Kan şekeri değerleri normalin üstünde', _diabetes, _diabetesMed,
              (v) { setState(() => _diabetes = v); if (!v) setState(() => _diabetesMed = false); _saveData(); },
              (v) { setState(() => _diabetesMed = v); _saveData(); }),
          _riskItemWithMed(Icons.bloodtype_rounded, 'Yüksek Kolesterol', 'Kolesterol veya trigliserit yüksekliği', _hyperlipidemia, _hyperlipidemiaMed,
              (v) { setState(() => _hyperlipidemia = v); if (!v) setState(() => _hyperlipidemiaMed = false); _saveData(); },
              (v) { setState(() => _hyperlipidemiaMed = v); _saveData(); }),

          const SizedBox(height: 20),

          // ── Warning ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _riskColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(_riskScore >= 25 ? Icons.warning_rounded : Icons.info_outline_rounded, color: _riskColor, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  _riskScore >= 50
                      ? 'Risk seviyeniz yüksek. En kısa sürede bir kardiyoloji uzmanına danışın.'
                      : _riskScore >= 25
                          ? 'Risk seviyeniz orta. Yaşam tarzı değişiklikleri ve doktor kontrolü önerilir.'
                          : 'Risk seviyeniz düşük. Sağlıklı alışkanlıklarınızı sürdürün!',
                  style: GoogleFonts.inter(fontSize: 13, color: _riskColor, fontWeight: FontWeight.w600, height: 1.4),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Bu değerlendirme tıbbi teşhis yerine geçmez.',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStressSelector() {
    const colors = [Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFFE53935)];
    const labels = ['Düşük', 'Orta', 'Yüksek'];
    const icons = [Icons.sentiment_satisfied_rounded, Icons.sentiment_neutral_rounded, Icons.sentiment_very_dissatisfied_rounded];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: colors[_stressLevel].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology_rounded, color: colors[_stressLevel], size: 20),
              ),
              const SizedBox(width: 12),
              Text('Stres Seviyesi', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (i) {
              final selected = _stressLevel == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () { setState(() => _stressLevel = i); _saveData(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? colors[i].withValues(alpha: 0.12) : AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: selected ? Border.all(color: colors[i], width: 2) : null,
                    ),
                    child: Column(
                      children: [
                        Icon(icons[i], color: selected ? colors[i] : AppTheme.textLight, size: 24),
                        const SizedBox(height: 4),
                        Text(labels[i], style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? colors[i] : AppTheme.textLight,
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(IconData icon, Color color, String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: value ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: color.withValues(alpha: 0.4),
        activeThumbColor: color,
        secondary: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: value ? 0.15 : 0.06), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: value ? color : AppTheme.textLight, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: value ? AppTheme.textDark : AppTheme.textLight)),
        subtitle: Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _riskItem(IconData icon, String title, String sub, bool value, bool? medValue, ValueChanged<bool> onChanged, ValueChanged<bool>? onMedChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: value ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)) : null,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryRed.withValues(alpha: 0.4),
        activeThumbColor: AppTheme.primaryRed,
        secondary: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: (value ? AppTheme.primaryRed : AppTheme.textLight).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: value ? AppTheme.primaryRed : AppTheme.textLight, size: 20),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark))),
            if (value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Risk', style: GoogleFonts.inter(color: AppTheme.primaryRed, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        subtitle: Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _riskItemWithMed(IconData icon, String title, String sub, bool value, bool medValue,
      ValueChanged<bool> onChanged, ValueChanged<bool> onMedChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: value ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryRed.withValues(alpha: 0.4),
            activeThumbColor: AppTheme.primaryRed,
            secondary: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: (value ? AppTheme.primaryRed : AppTheme.textLight).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: value ? AppTheme.primaryRed : AppTheme.textLight, size: 20),
            ),
            title: Row(
              children: [
                Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark))),
                if (value)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('Risk', style: GoogleFonts.inter(color: AppTheme.primaryRed, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            subtitle: Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          if (value) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: GestureDetector(
                onTap: () => onMedChanged(!medValue),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: medValue ? const Color(0xFF42A5F5).withValues(alpha: 0.08) : AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: medValue ? Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.3)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: medValue ? const Color(0xFF42A5F5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: medValue ? const Color(0xFF42A5F5) : AppTheme.textLight.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: medValue ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.medication_rounded, size: 16,
                          color: medValue ? const Color(0xFF42A5F5) : AppTheme.textLight),
                      const SizedBox(width: 6),
                      Text('İlaç kullanıyorum',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: medValue ? FontWeight.w700 : FontWeight.w500,
                            color: medValue ? const Color(0xFF42A5F5) : AppTheme.textLight,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBmiBar() {
    return Row(
      children: [
        _bmiSeg('Zayıf', Colors.blue, _bmi < 18.5),
        const SizedBox(width: 3),
        _bmiSeg('Normal', Colors.green, _bmi >= 18.5 && _bmi < 25),
        const SizedBox(width: 3),
        _bmiSeg('Kilolu', Colors.orange, _bmi >= 25 && _bmi < 30),
        const SizedBox(width: 3),
        _bmiSeg('Obez', AppTheme.primaryRed, _bmi >= 30),
      ],
    );
  }

  Widget _bmiSeg(String label, Color color, bool active) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: active ? color : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: active ? color : AppTheme.textLight, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _RiskGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter old) => old.progress != progress || old.color != color;
}
