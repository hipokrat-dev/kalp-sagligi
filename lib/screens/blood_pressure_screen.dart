import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Tansiyon / Nabiz Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        labelText: 'Buyuk Tansiyon',
                        suffixText: 'mmHg',
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Kucuk Tansiyon',
                        suffixText: 'mmHg',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pulseCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Nabiz',
                  suffixText: 'bpm',
                  prefixIcon: Icon(Icons.favorite),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Not (istege bagli)',
                  hintText: 'Orn: egzersiz sonrasi',
                ),
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
    );

    if (result == true) {
      final systolic = int.tryParse(systolicCtrl.text);
      final diastolic = int.tryParse(diastolicCtrl.text);
      final pulse = int.tryParse(pulseCtrl.text);
      if (systolic != null && diastolic != null && pulse != null) {
        await _storage.addBloodPressureRecord(BloodPressureRecord(
          date: DateTime.now(),
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
                    width: 80,
                    height: 80,
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
                // Latest Reading Card
                if (_records.isNotEmpty) ...[
                  _buildLatestCard(_records.first),
                  const SizedBox(height: 20),
                ],

                // BP Reference Card
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
                        spacing: 8,
                        runSpacing: 8,
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
                        // Colored left border
                        Container(
                          width: 4,
                          height: 80,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
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
                                          Text(
                                            '${r.systolic}/${r.diastolic}',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
                                          ),
                                          Text(' mmHg', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
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
                                      Text(
                                        'Nabiz: ${r.pulse} bpm  -  ${r.date.day}/${r.date.month}/${r.date.year} ${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                                      ),
                                      if (r.note != null)
                                        Text(r.note!, style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textLight)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await _storage.deleteBloodPressureRecord(i);
                                    _loadData();
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
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
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('SON OLCUM', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${r.systolic}/${r.diastolic}',
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
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
                      Text(
                        '${r.pulse}',
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
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
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.riskLevel,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
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
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $range',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
