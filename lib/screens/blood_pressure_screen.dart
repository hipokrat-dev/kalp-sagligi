import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/health_data.dart';
import 'reminder_settings_screen.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  final _storage = StorageService.instance;
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  List<BloodPressureRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final records = await _storage.getBloodPressureRecords();
    if (mounted) setState(() => _records = records);
  }

  void _saveRecord() async {
    final sys = int.tryParse(_systolicCtrl.text);
    final dia = int.tryParse(_diastolicCtrl.text);
    final pulse = int.tryParse(_pulseCtrl.text);
    if (sys == null || dia == null || pulse == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    await _storage.addBloodPressureRecord(BloodPressureRecord(
      date: DateTime.now(),
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
    ));
    _systolicCtrl.clear();
    _diastolicCtrl.clear();
    _pulseCtrl.clear();
    FocusScope.of(context).unfocus();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ölçüm kaydedildi', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Color _statusColor(String level) {
    return switch (level) {
      'Normal' => const Color(0xFF4CAF50),
      'Normal Ustu' => const Color(0xFFFFC107),
      'Yukselmis' => const Color(0xFFFF9800),
      'Yuksek' => const Color(0xFFE53935),
      'Kriz' => const Color(0xFFB71C1C),
      _ => Colors.grey,
    };
  }

  String _statusMessage(String level) {
    return switch (level) {
      'Normal' => 'Tansiyonunuz normal aralıkta. Böyle devam edin!',
      'Normal Ustu' => 'Tansiyonunuz normal üstünde. Tuz tüketimini azaltın.',
      'Yukselmis' => 'Tansiyonunuz yükselmiş. Doktorunuza danışmanız önerilir.',
      'Yuksek' => 'Tansiyonunuz yüksek! Lütfen doktorunuza başvurun.',
      'Kriz' => 'Hipertansif kriz! Acil tıbbi yardım alın!',
      _ => '',
    };
  }

  // Get weekly data for chart (last 7 days, one per day - latest)
  List<BloodPressureRecord?> _getWeeklyData() {
    final now = DateTime.now();
    final result = <BloodPressureRecord?>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayRecords = _records.where((r) =>
          r.date.year == day.year && r.date.month == day.month && r.date.day == day.day);
      result.add(dayRecords.isNotEmpty ? dayRecords.first : null);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final weeklyData = _getWeeklyData();
    final hasChartData = weeklyData.any((r) => r != null);
    final lastRecord = _records.isNotEmpty ? _records.first : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.darkRed,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Tansiyon Günlüğü', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          // ── Input Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _buildInputRow(
                  icon: Icons.favorite_rounded,
                  iconColor: AppTheme.primaryRed,
                  label: 'Sistolik',
                  controller: _systolicCtrl,
                  hint: '120',
                  range: '90-180',
                ),
                const SizedBox(height: 14),
                _buildInputRow(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFFFF9800),
                  label: 'Diyastolik',
                  controller: _diastolicCtrl,
                  hint: '80',
                  range: '60-110',
                ),
                const SizedBox(height: 14),
                _buildInputRow(
                  icon: Icons.monitor_heart_rounded,
                  iconColor: const Color(0xFF7E57C2),
                  label: 'Nabız',
                  controller: _pulseCtrl,
                  hint: '72',
                  range: '50-100',
                ),
                const SizedBox(height: 20),
                // Save button
                GestureDetector(
                  onTap: _saveRecord,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFC0392B), Color(0xFFE74C3C)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
                    ),
                    child: Center(
                      child: Text('Kaydet', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Weekly Chart ──
          if (hasChartData)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 18, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Text('HAFTALIK TAKİP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                        const Spacer(),
                        _legendDot(AppTheme.primaryRed, 'Sistolik'),
                        const SizedBox(width: 10),
                        _legendDot(const Color(0xFFFF9800), 'Diyastolik'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minY: 50,
                        maxY: 190,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 30,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= 7) return const SizedBox.shrink();
                                final now = DateTime.now();
                                final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(weekDays[day.weekday - 1],
                                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        // Background bands: Normal / Yüksek / Hipertansiyon
                        rangeAnnotations: RangeAnnotations(
                          horizontalRangeAnnotations: [
                            HorizontalRangeAnnotation(y1: 50, y2: 120, color: const Color(0xFF4CAF50).withValues(alpha: 0.08)),
                            HorizontalRangeAnnotation(y1: 120, y2: 140, color: const Color(0xFFFFC107).withValues(alpha: 0.10)),
                            HorizontalRangeAnnotation(y1: 140, y2: 190, color: const Color(0xFFE53935).withValues(alpha: 0.08)),
                          ],
                        ),
                        lineBarsData: [
                          // Systolic
                          _buildChartLine(weeklyData, (r) => r.systolic.toDouble(), AppTheme.primaryRed),
                          // Diastolic
                          _buildChartLine(weeklyData, (r) => r.diastolic.toDouble(), const Color(0xFFFF9800)),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((spot) {
                              final color = spot.barIndex == 0 ? AppTheme.primaryRed : const Color(0xFFFF9800);
                              final label = spot.barIndex == 0 ? 'Sis' : 'Dia';
                              return LineTooltipItem(
                                '$label: ${spot.y.toInt()}',
                                GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Band labels
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Row(
                      children: [
                        _bandLabel(const Color(0xFF4CAF50), 'Normal'),
                        const SizedBox(width: 12),
                        _bandLabel(const Color(0xFFFFC107), 'Yüksek'),
                        const SizedBox(width: 12),
                        _bandLabel(const Color(0xFFE53935), 'Hipertansiyon'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (hasChartData) const SizedBox(height: 20),

          // ── Son Kayıt ──
          if (lastRecord != null)
            _buildLastRecordCard(lastRecord),
          if (lastRecord != null) const SizedBox(height: 20),

          // ── Geçmiş ──
          if (_records.length > 1) ...[
            Text('GEÇMİŞ KAYITLAR', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...List.generate(_records.length.clamp(0, 20), (i) {
              final r = _records[i];
              final color = _statusColor(r.riskLevel);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 44,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${r.systolic}/${r.diastolic}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark)),
                              Text(' mmHg', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
                              const SizedBox(width: 8),
                              Icon(Icons.favorite_rounded, size: 12, color: const Color(0xFF7E57C2).withValues(alpha: 0.7)),
                              const SizedBox(width: 2),
                              Text('${r.pulse}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}/${r.date.year}  ${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r.riskLevel, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await _storage.deleteBloodPressureRecord(i);
                        _loadData();
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textLight.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required String hint,
    required String range,
  }) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.textLight.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(range, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  LineChartBarData _buildChartLine(
      List<BloodPressureRecord?> data, double Function(BloodPressureRecord) getValue, Color color) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i] != null) spots.add(FlSpot(i.toDouble(), getValue(data[i]!)));
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 4, color: color, strokeWidth: 2, strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.06)),
    );
  }

  Widget _buildLastRecordCard(BloodPressureRecord r) {
    final color = _statusColor(r.riskLevel);
    final message = _statusMessage(r.riskLevel);
    final time = '${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}';
    final date = '${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}/${r.date.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SON KAYIT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text('$date  $time', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Values
              Expanded(
                child: Row(
                  children: [
                    Text('${r.systolic}/${r.diastolic}',
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    const SizedBox(width: 6),
                    Text('mmHg', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight)),
                  ],
                ),
              ),
              // Nabız
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 14, color: const Color(0xFF7E57C2)),
                      const SizedBox(width: 4),
                      Text('${r.pulse}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    ],
                  ),
                  Text('bpm', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status badge + message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    r.riskLevel == 'Normal' ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: color, size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.riskLevel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                      Text(message, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _bandLabel(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
