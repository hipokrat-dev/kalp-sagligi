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
  List<BloodPressureRecord> _records = [];
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _storage.getBloodPressureRecords();
    if (mounted) setState(() => _records = records);
  }

  void _addRecord() async {
    final systolicCtrl = TextEditingController();
    final diastolicCtrl = TextEditingController();
    final pulseCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
          title: Text('Tansiyon / Nabiz Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date & Time picker
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textLight),
                        const SizedBox(width: 10),
                        Text(
                          '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(context: ctx, initialTime: selectedTime);
                            if (time != null) setDState(() => selectedTime = time);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primaryRed),
                                const SizedBox(width: 4),
                                Text(
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primaryRed, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: systolicCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(labelText: 'Buyuk', suffixText: 'mmHg'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('/', style: GoogleFonts.inter(fontSize: 24, color: AppTheme.textLight)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: diastolicCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(labelText: 'Kucuk', suffixText: 'mmHg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pulseCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(labelText: 'Nabiz', suffixText: 'bpm', prefixIcon: Icon(Icons.favorite)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(labelText: 'Not (istege bagli)', hintText: 'Orn: egzersiz sonrasi'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final systolic = int.tryParse(systolicCtrl.text);
      final diastolic = int.tryParse(diastolicCtrl.text);
      final pulse = int.tryParse(pulseCtrl.text);
      if (systolic != null && diastolic != null && pulse != null) {
        final recordDate = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day,
          selectedTime.hour, selectedTime.minute,
        );
        await _storage.addBloodPressureRecord(BloodPressureRecord(
          date: recordDate,
          systolic: systolic,
          diastolic: diastolic,
          pulse: pulse,
          note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
        ));
        _loadData();
      }
    }
  }

  Color _riskColor(String level) {
    return switch (level) {
      'Normal' => Colors.green,
      'Normal Ustu' => Colors.amber,
      'Yukselmis' => Colors.orange,
      'Yuksek' => AppTheme.primaryRed,
      'Kriz' => AppTheme.darkRed,
      _ => Colors.grey,
    };
  }

  List<Color> _riskGradient(String level) {
    return switch (level) {
      'Normal' => const [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
      'Normal Ustu' => const [Color(0xFFFDD835), Color(0xFFFFF176)],
      'Yukselmis' => const [Color(0xFFFF9800), Color(0xFFFFB74D)],
      'Yuksek' => const [Color(0xFFE53935), Color(0xFFFF6B6B)],
      'Kriz' => const [Color(0xFFB71C1C), Color(0xFFE53935)],
      _ => [Colors.grey, Colors.grey.shade300],
    };
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime d) => '${_formatDate(d)} ${_formatTime(d)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Tansiyon & Nabiz', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        actions: [
          if (_records.length >= 2)
            GestureDetector(
              onTap: () => setState(() => _showChart = !_showChart),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _showChart ? AppTheme.primaryRed.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Icon(
                  _showChart ? Icons.list_rounded : Icons.show_chart_rounded,
                  color: _showChart ? AppTheme.primaryRed : AppTheme.textDark,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.notifications_active_rounded, color: AppTheme.textDark, size: 18),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _addRecord,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient2,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Olcum Ekle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
      body: _records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.monitor_heart_rounded, size: 40, color: AppTheme.primaryRed.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 16),
                  Text('Henuz kayit yok', style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('Ilk tansiyon olcumunuzu kaydedin', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                // Latest Reading
                _buildLatestCard(_records.first),
                const SizedBox(height: 20),

                // Chart (toggle)
                if (_showChart && _records.length >= 2) ...[
                  _buildChartCard(),
                  const SizedBox(height: 20),
                ],

                // Reference
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
                      Text('REFERANS DEGERLER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _buildRefPill('Normal', '<120/<80', Colors.green),
                          _buildRefPill('Normal Ustu', '120-129/<80', Colors.amber),
                          _buildRefPill('Yukselmis', '130-139/80-89', Colors.orange),
                          _buildRefPill('Yuksek', '>=140/>=90', AppTheme.primaryRed),
                          _buildRefPill('Kriz', '>=180/>=120', AppTheme.darkRed),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // History
                Text('GECMIS KAYITLAR', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 12),
                ...List.generate(_records.length, (i) {
                  final r = _records[i];
                  final color = _riskColor(r.riskLevel);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4, height: 88,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(22),
                              bottomLeft: Radius.circular(22),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.monitor_heart_rounded, color: color, size: 20),
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
                                          Text(' mmHg', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(r.riskLevel, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.favorite_rounded, size: 12, color: AppTheme.primaryRed.withValues(alpha: 0.6)),
                                          const SizedBox(width: 3),
                                          Text('${r.pulse} bpm', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textLight.withValues(alpha: 0.6)),
                                          const SizedBox(width: 3),
                                          Text(_formatDateTime(r.date),
                                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      if (r.note != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(r.note!, style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textLight)),
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await _storage.deleteBloodPressureRecord(i);
                                    _loadData();
                                  },
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.textLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildLatestCard(BloodPressureRecord r) {
    final colors = _riskGradient(r.riskLevel);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SON OLCUM', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_formatDateTime(r.date),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text('${r.systolic}/${r.diastolic}', style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('mmHg', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(width: 32),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text('${r.pulse}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  Text('bpm', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
            child: Text(r.riskLevel, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    // Last 10 records reversed (oldest first)
    final chartRecords = _records.take(10).toList().reversed.toList();
    if (chartRecords.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
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
              Text('TANSIYON GRAFIGI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
              const Spacer(),
              Text('Son ${chartRecords.length} olcum', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _legendDot(AppTheme.primaryRed, 'Sistolik'),
              const SizedBox(width: 12),
              _legendDot(Colors.blue, 'Diastolik'),
              const SizedBox(width: 12),
              _legendDot(Colors.orange, 'Nabiz'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 30,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight),
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
                        if (i < 0 || i >= chartRecords.length) return const SizedBox.shrink();
                        final d = chartRecords[i].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textLight),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 40,
                maxY: 200,
                lineBarsData: [
                  // Systolic
                  LineChartBarData(
                    spots: List.generate(chartRecords.length, (i) =>
                        FlSpot(i.toDouble(), chartRecords[i].systolic.toDouble())),
                    isCurved: true,
                    color: AppTheme.primaryRed,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4, color: AppTheme.primaryRed,
                        strokeWidth: 2, strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryRed.withValues(alpha: 0.08),
                    ),
                  ),
                  // Diastolic
                  LineChartBarData(
                    spots: List.generate(chartRecords.length, (i) =>
                        FlSpot(i.toDouble(), chartRecords[i].diastolic.toDouble())),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4, color: Colors.blue,
                        strokeWidth: 2, strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.08),
                    ),
                  ),
                  // Pulse
                  LineChartBarData(
                    spots: List.generate(chartRecords.length, (i) =>
                        FlSpot(i.toDouble(), chartRecords[i].pulse.toDouble())),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    dashArray: [5, 3],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3, color: Colors.orange,
                        strokeWidth: 2, strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final color = spot.barIndex == 0 ? AppTheme.primaryRed
                          : spot.barIndex == 1 ? Colors.blue : Colors.orange;
                      final label = spot.barIndex == 0 ? 'Sis' : spot.barIndex == 1 ? 'Dia' : 'Nabiz';
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
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRefPill(String label, String range, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label $range', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
