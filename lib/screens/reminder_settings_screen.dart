import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final _storage = StorageService.instance;

  bool _waterEnabled = true;
  int _waterMinutes = 120;
  String _waterStart = '08:00';
  String _waterEnd = '22:00';

  bool _movementEnabled = true;
  int _movementMinutes = 60;
  String _movementStart = '08:00';
  String _movementEnd = '22:00';

  bool _bpEnabled = true;
  int _bpMinutes = 480;
  String _bpStart = '09:00';
  String _bpEnd = '21:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final we = await _storage.getReminderEnabled('water');
    final wm = await _storage.getReminderInterval('water');
    final ws = await _storage.getReminderStartTime('water');
    final wend = await _storage.getReminderEndTime('water');

    final me = await _storage.getReminderEnabled('movement');
    final mm = await _storage.getReminderInterval('movement');
    final ms = await _storage.getReminderStartTime('movement');
    final mend = await _storage.getReminderEndTime('movement');

    final be = await _storage.getReminderEnabled('bp');
    final bm = await _storage.getReminderInterval('bp');
    final bs = await _storage.getReminderStartTime('bp');
    final bend = await _storage.getReminderEndTime('bp');

    if (mounted) {
      setState(() {
        _waterEnabled = we; _waterMinutes = wm; _waterStart = ws; _waterEnd = wend;
        _movementEnabled = me; _movementMinutes = mm; _movementStart = ms; _movementEnd = mend;
        _bpEnabled = be; _bpMinutes = bm; _bpStart = bs; _bpEnd = bend;
      });
    }
  }

  Future<void> _saveAndApply() async {
    await _storage.setReminderEnabled('water', _waterEnabled);
    await _storage.setReminderInterval('water', _waterMinutes);
    await _storage.setReminderStartTime('water', _waterStart);
    await _storage.setReminderEndTime('water', _waterEnd);

    await _storage.setReminderEnabled('movement', _movementEnabled);
    await _storage.setReminderInterval('movement', _movementMinutes);
    await _storage.setReminderStartTime('movement', _movementStart);
    await _storage.setReminderEndTime('movement', _movementEnd);

    await _storage.setReminderEnabled('bp', _bpEnabled);
    await _storage.setReminderInterval('bp', _bpMinutes);
    await _storage.setReminderStartTime('bp', _bpStart);
    await _storage.setReminderEndTime('bp', _bpEnd);

    AlarmService.instance.startTimers(
      waterMinutes: _waterMinutes,
      movementMinutes: _movementMinutes,
      bpMinutes: _bpMinutes,
      waterEnabled: _waterEnabled,
      movementEnabled: _movementEnabled,
      bpEnabled: _bpEnabled,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hatırlatma ayarları kaydedildi'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _pickTime(String current, ValueChanged<String> onPicked) async {
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPicked('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hatırlatma Ayarları')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hatırlatmaları özelleştirin',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight)),
          const SizedBox(height: 16),

          _buildReminderSection(
            icon: Icons.water_drop_rounded,
            title: 'Su İçme Hatırlatması',
            color: const Color(0xFF42A5F5),
            enabled: _waterEnabled,
            onEnabledChanged: (v) => setState(() => _waterEnabled = v),
            minutes: _waterMinutes,
            minuteOptions: const [30, 60, 90, 120, 180],
            onMinutesChanged: (v) => setState(() => _waterMinutes = v),
            startTime: _waterStart,
            endTime: _waterEnd,
            onStartChanged: (v) => setState(() => _waterStart = v),
            onEndChanged: (v) => setState(() => _waterEnd = v),
          ),

          _buildReminderSection(
            icon: Icons.directions_walk_rounded,
            title: 'Hareket Hatırlatması',
            color: const Color(0xFFFF9800),
            enabled: _movementEnabled,
            onEnabledChanged: (v) => setState(() => _movementEnabled = v),
            minutes: _movementMinutes,
            minuteOptions: const [30, 45, 60, 90, 120],
            onMinutesChanged: (v) => setState(() => _movementMinutes = v),
            startTime: _movementStart,
            endTime: _movementEnd,
            onStartChanged: (v) => setState(() => _movementStart = v),
            onEndChanged: (v) => setState(() => _movementEnd = v),
          ),

          _buildReminderSection(
            icon: Icons.monitor_heart_rounded,
            title: 'Tansiyon Ölçüm Hatırlatması',
            color: AppTheme.primaryRed,
            enabled: _bpEnabled,
            onEnabledChanged: (v) => setState(() => _bpEnabled = v),
            minutes: _bpMinutes,
            minuteOptions: const [240, 360, 480, 720],
            onMinutesChanged: (v) => setState(() => _bpMinutes = v),
            startTime: _bpStart,
            endTime: _bpEnd,
            onStartChanged: (v) => setState(() => _bpStart = v),
            onEndChanged: (v) => setState(() => _bpEnd = v),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveAndApply,
              icon: const Icon(Icons.check_rounded),
              label: Text('Kaydet ve Uygula',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatMinutes(int m) {
    if (m < 60) return '$m dk';
    final h = m ~/ 60;
    final r = m % 60;
    return r > 0 ? '$h sa $r dk' : '$h saat';
  }

  Widget _buildReminderSection({
    required IconData icon,
    required String title,
    required Color color,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required int minutes,
    required List<int> minuteOptions,
    required ValueChanged<int> onMinutesChanged,
    required String startTime,
    required String endTime,
    required ValueChanged<String> onStartChanged,
    required ValueChanged<String> onEndChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          SwitchListTile(
            value: enabled,
            onChanged: onEnabledChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            secondary: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),

          if (enabled) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interval
                  Text('Sıklık',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: minuteOptions.map((m) {
                      final selected = minutes == m;
                      return ChoiceChip(
                        label: Text(_formatMinutes(m)),
                        selected: selected,
                        selectedColor: color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: selected ? color : AppTheme.textLight,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        side: BorderSide(color: selected ? color : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (_) => onMinutesChanged(m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Time range
                  Text('Aktif Saat Aralığı',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeButton(
                          label: 'Başlangıç',
                          time: startTime,
                          color: color,
                          onTap: () => _pickTime(startTime, onStartChanged),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 16, color: AppTheme.textLight),
                      ),
                      Expanded(
                        child: _TimeButton(
                          label: 'Bitiş',
                          time: endTime,
                          color: color,
                          onTap: () => _pickTime(endTime, onEndChanged),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.time, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
                Text(time, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
