import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/health_data.dart';

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
        title: const Text('Tansiyon / Nabız Kaydet'),
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
                      decoration: const InputDecoration(
                        labelText: 'Büyük Tansiyon',
                        suffixText: 'mmHg',
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/', style: TextStyle(fontSize: 24)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: diastolicCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Küçük Tansiyon',
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
                decoration: const InputDecoration(
                  labelText: 'Nabız',
                  suffixText: 'bpm',
                  prefixIcon: Icon(Icons.favorite),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Not (isteğe bağlı)',
                  hintText: 'Örn: egzersiz sonrası',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
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
      'Normal Üstü' => Colors.amber,
      'Yükselmiş' => Colors.orange,
      'Yüksek' => AppTheme.primaryRed,
      'Kriz' => AppTheme.darkRed,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tansiyon & Nabız')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('Ölçüm Ekle'),
      ),
      body: _records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Henüz kayıt yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const Text('İlk tansiyon ölçümünüzü kaydedin', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Latest Reading
                if (_records.isNotEmpty) ...[
                  _buildLatestCard(_records.first),
                  const SizedBox(height: 16),
                ],

                // BP Reference Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tansiyon Referans Değerleri',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        _buildRefRow('Normal', '<120 / <80', Colors.green),
                        _buildRefRow('Normal Üstü', '120-129 / <80', Colors.amber),
                        _buildRefRow('Yükselmiş', '130-139 / 80-89', Colors.orange),
                        _buildRefRow('Yüksek', '≥140 / ≥90', AppTheme.primaryRed),
                        _buildRefRow('Kriz', '≥180 / ≥120', AppTheme.darkRed),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // History
                const Text('Geçmiş Kayıtlar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...List.generate(_records.length, (i) {
                  final r = _records[i];
                  final color = _riskColor(r.riskLevel);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(Icons.monitor_heart, color: color, size: 20),
                      ),
                      title: Text(
                        '${r.systolic}/${r.diastolic} mmHg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nabız: ${r.pulse} bpm  •  ${r.riskLevel}'),
                          Text(
                            '${r.date.day}/${r.date.month}/${r.date.year} ${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                          ),
                          if (r.note != null)
                            Text(r.note!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          await _storage.deleteBloodPressureRecord(i);
                          _loadData();
                        },
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildLatestCard(BloodPressureRecord r) {
    final color = _riskColor(r.riskLevel);
    return Card(
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Son Ölçüm', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '${r.systolic}/${r.diastolic}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
                    ),
                    const Text('mmHg', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${r.pulse}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Text('bpm', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                r.riskLevel,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(range, style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}
