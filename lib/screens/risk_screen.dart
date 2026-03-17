import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  final _storage = StorageService.instance;

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
    _loadData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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
  }

  double get _bmi {
    if (_height <= 0 || _weight <= 0) return 0;
    final heightM = _height / 100;
    return _weight / (heightM * heightM);
  }

  String get _bmiCategory {
    if (_bmi <= 0) return 'Hesaplanamadı';
    if (_bmi < 18.5) return 'Zayıf';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Fazla Kilolu';
    if (_bmi < 35) return 'Obez (Sınıf I)';
    if (_bmi < 40) return 'Obez (Sınıf II)';
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

    // BMI risk
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
    if (_riskScore >= 60) return 'Yüksek Risk';
    if (_riskScore >= 35) return 'Orta Risk';
    if (_riskScore > 0) return 'Düşük Risk';
    return 'Değerlendirilmedi';
  }

  Color get _riskColor {
    if (_riskScore >= 60) return AppTheme.primaryRed;
    if (_riskScore >= 35) return Colors.orange;
    if (_riskScore > 0) return Colors.green;
    return Colors.grey;
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
      appBar: AppBar(title: const Text('Kalp Riski Değerlendirmesi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Risk Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Kalp Hastalığı Risk Skoru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _riskScore / 100,
                          strokeWidth: 14,
                          backgroundColor: _riskColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(_riskColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$_riskScore',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: _riskColor,
                            ),
                          ),
                          Text(
                            _riskLevel,
                            style: TextStyle(color: _riskColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_checkedCount / 7 risk faktörü tespit edildi',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Risk Checklist
          const Text(
            'Risk Faktörleri Kontrol Listesi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          _buildCheckItem(
            icon: Icons.family_restroom,
            title: 'Aile Öyküsü',
            subtitle: 'Ailede erken yaşta kalp hastalığı (erkek <55, kadın <65 yaş)',
            value: _familyHistory,
            riskPoints: 20,
            onChanged: (v) {
              setState(() => _familyHistory = v);
              _saveData();
            },
          ),

          _buildCheckItem(
            icon: Icons.smoking_rooms,
            title: 'Sigara Kullanımı',
            subtitle: 'Aktif sigara kullanıyorum veya son 5 yılda bıraktım',
            value: _smoking,
            riskPoints: 20,
            onChanged: (v) {
              setState(() => _smoking = v);
              _saveData();
            },
          ),

          _buildCheckItem(
            icon: Icons.monitor_heart,
            title: 'Hipertansiyon',
            subtitle: 'Yüksek tansiyon tanısı var veya ilaç kullanıyorum',
            value: _hypertension,
            riskPoints: 15,
            onChanged: (v) {
              setState(() => _hypertension = v);
              _saveData();
            },
          ),

          _buildCheckItem(
            icon: Icons.bloodtype,
            title: 'Hiperlipidemi',
            subtitle: 'Yüksek kolesterol / trigliserit tanısı var',
            value: _hyperlipidemia,
            riskPoints: 15,
            onChanged: (v) {
              setState(() => _hyperlipidemia = v);
              _saveData();
            },
          ),

          _buildCheckItem(
            icon: Icons.water_drop,
            title: 'Diyabet',
            subtitle: 'Tip 1 veya Tip 2 diyabet tanısı var',
            value: _diabetes,
            riskPoints: 15,
            onChanged: (v) {
              setState(() => _diabetes = v);
              _saveData();
            },
          ),

          _buildCheckItem(
            icon: Icons.weekend,
            title: 'Hareketsizlik',
            subtitle: 'Haftada 150 dakikadan az egzersiz yapıyorum',
            value: _inactivity,
            riskPoints: 10,
            onChanged: (v) {
              setState(() => _inactivity = v);
              _saveData();
            },
          ),

          const SizedBox(height: 16),

          // BMI Calculator
          const Text(
            'Boy / Kilo / VKİ Hesaplama',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Boy',
                            suffixText: 'cm',
                            prefixIcon: Icon(Icons.height),
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
                          decoration: const InputDecoration(
                            labelText: 'Kilo',
                            suffixText: 'kg',
                            prefixIcon: Icon(Icons.monitor_weight),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _bmiColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _bmiColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text('Vücut Kitle İndeksi (VKİ)',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _bmi.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _bmiColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _bmiColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _bmiCategory,
                              style: TextStyle(
                                color: _bmiColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (_bmi >= 25) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber, color: _bmiColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Risk skora +${_bmi >= 30 ? 15 : 8} puan eklendi',
                                  style: TextStyle(fontSize: 12, color: _bmiColor),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // BMI Scale
                    Row(
                      children: [
                        _buildBmiRange('Zayıf', '<18.5', Colors.blue),
                        _buildBmiRange('Normal', '18.5-25', Colors.green),
                        _buildBmiRange('Fazla', '25-30', Colors.orange),
                        _buildBmiRange('Obez', '>30', AppTheme.primaryRed),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Doctor Warning
          if (_riskScore > 0)
            Card(
              color: _riskScore >= 35
                  ? AppTheme.primaryRed.withValues(alpha: 0.08)
                  : Colors.orange.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _riskScore >= 35
                      ? AppTheme.primaryRed.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _riskScore >= 35 ? Icons.warning : Icons.info_outline,
                          color: _riskScore >= 35 ? AppTheme.primaryRed : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _riskScore >= 60
                                ? 'Acil Doktor Görüşmesi Önerilir!'
                                : _riskScore >= 35
                                    ? 'Doktorunuzla Görüşmeniz Önerilir'
                                    : 'Düzenli Kontrol Önerisi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _riskScore >= 35 ? AppTheme.primaryRed : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getDoctorAdvice(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_hospital, color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Bu değerlendirme tıbbi teşhis yerine geçmez. '
                            'Risklerinizle ilgili mutlaka bir kardiyoloji uzmanına danışın.',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Risk Factor Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryRed, size: 20),
                      const SizedBox(width: 8),
                      const Text('Risk Faktörleri Hakkında',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Aile Öyküsü',
                      'Birinci derece akrabalarınızda erken yaşta koroner arter hastalığı öyküsü riski 2 kat artırır.'),
                  _buildInfoRow('Sigara',
                      'Sigara, damar sertliğini hızlandırır ve kalp krizi riskini 2-4 kat artırır.'),
                  _buildInfoRow('Hipertansiyon',
                      'Kontrolsüz yüksek tansiyon kalp yetmezliği, inme ve böbrek hasarına yol açabilir.'),
                  _buildInfoRow('Hiperlipidemi',
                      'Yüksek LDL kolesterol damarlarda plak birikimine neden olarak damar tıkanıklığına yol açar.'),
                  _buildInfoRow('Diyabet',
                      'Diyabet damar yapısını bozar, kalp hastalığı riskini 2-4 kat artırır.'),
                  _buildInfoRow('Hareketsizlik',
                      'Düzenli egzersiz yapmamak kardiyovasküler hastalık riskini önemli ölçüde artırır.'),
                  _buildInfoRow('Obezite (VKİ)',
                      'VKİ 25 üzeri kalp hastalığı, hipertansiyon ve diyabet riskini artırır.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getDoctorAdvice() {
    final risks = <String>[];
    if (_familyHistory) risks.add('aile öyküsü');
    if (_smoking) risks.add('sigara kullanımı');
    if (_hypertension) risks.add('hipertansiyon');
    if (_hyperlipidemia) risks.add('hiperlipidemi');
    if (_diabetes) risks.add('diyabet');
    if (_inactivity) risks.add('hareketsizlik');
    if (_bmi >= 25) risks.add('yüksek VKİ (${_bmi.toStringAsFixed(1)})');

    if (_riskScore >= 60) {
      return 'Toplam $_checkedCount risk faktörünüz tespit edildi: '
          '${risks.join(", ")}. '
          'Bu risk profili ile en kısa sürede bir kardiyoloji uzmanına başvurmanız '
          've kapsamlı bir kalp sağlığı değerlendirmesi yaptırmanız şiddetle önerilir.';
    } else if (_riskScore >= 35) {
      return 'Tespit edilen risk faktörleriniz: ${risks.join(", ")}. '
          'Bu risklerin yönetimi için doktorunuzla görüşerek kişisel bir '
          'tedavi ve yaşam tarzı planı oluşturmanız önerilir.';
    } else {
      return 'Tespit edilen risk faktörleriniz: ${risks.join(", ")}. '
          'Risk seviyeniz düşük olsa da düzenli sağlık kontrolleri yaptırmaya devam edin.';
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
    final color = value ? AppTheme.primaryRed : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: value
            ? BorderSide(color: AppTheme.primaryRed.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      color: value ? AppTheme.primaryRed.withValues(alpha: 0.04) : null,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryRed.withValues(alpha: 0.5),
        activeThumbColor: AppTheme.primaryRed,
        secondary: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            if (value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$riskPoints',
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text(range, style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
          Icon(Icons.circle, size: 8, color: AppTheme.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12.5, color: AppTheme.textDark, height: 1.3),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
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
