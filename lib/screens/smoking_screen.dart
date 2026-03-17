import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class SmokingScreen extends StatefulWidget {
  const SmokingScreen({super.key});

  @override
  State<SmokingScreen> createState() => _SmokingScreenState();
}

class _SmokingScreenState extends State<SmokingScreen> {
  final _storage = StorageService.instance;
  DateTime? _quitDate;
  int _dailyCount = 20;
  double _packPrice = 60.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final quitDate = await _storage.getSmokingQuitDate();
    final count = await _storage.getDailySmokingCount();
    final price = await _storage.getPackPrice();
    if (mounted) {
      setState(() {
        _quitDate = quitDate;
        _dailyCount = count;
        _packPrice = price;
      });
    }
  }

  void _startCounter() async {
    final countController = TextEditingController(text: _dailyCount.toString());
    final priceController = TextEditingController(text: _packPrice.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sigara Bırakma Sayacı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bugün sigarayı bırakıyorsun! Bilgilerini gir:'),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Günlük sigara sayısı',
                suffixText: 'adet',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Paket fiyatı',
                suffixText: 'TL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Başla'),
          ),
        ],
      ),
    );

    if (result == true) {
      final count = int.tryParse(countController.text) ?? 20;
      final price = double.tryParse(priceController.text) ?? 60.0;
      await _storage.setSmokingQuitDate(DateTime.now());
      await _storage.setDailySmokingCount(count);
      await _storage.setPackPrice(price);
      _loadData();
    }
  }

  void _resetCounter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayacı Sıfırla'),
        content: const Text('Sayacı sıfırlamak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.clearSmokingQuitDate();
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quitDate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sigara Bırakma')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.smoke_free, size: 80, color: Colors.teal.shade300),
                const SizedBox(height: 24),
                const Text(
                  'Sigarayı Bırakmaya Hazır mısın?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sigara bırakma sayacını başlatarak ilerlemenizi takip edin. '
                  'Ne kadar para biriktirdiğinizi ve sağlığınıza katkısını görün.',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startCounter,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Sayacı Başlat', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final diff = now.difference(_quitDate!);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final cigarettesNotSmoked = days * _dailyCount;
    final moneySaved = (days * _dailyCount / 20 * _packPrice);
    final minutesOfLife = cigarettesNotSmoked * 11; // each cigarette ~11 min

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sigara Bırakma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'Sıfırla',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Counter
          Card(
            color: Colors.teal,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.smoke_free, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'SİGARASIZ GEÇİRDİĞİN SÜRE',
                    style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$days gün $hours saat $minutes dakika',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Başlangıç: ${_quitDate!.day}/${_quitDate!.month}/${_quitDate!.year}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                Icons.money,
                '${moneySaved.toStringAsFixed(0)} TL',
                'Biriken Para',
                Colors.green,
              ),
              _buildStatCard(
                Icons.no_drinks,
                '$cigarettesNotSmoked',
                'İçilmeyen Sigara',
                Colors.orange,
              ),
              _buildStatCard(
                Icons.favorite,
                '${(minutesOfLife / 60).toStringAsFixed(0)} saat',
                'Kazanılan Ömür',
                AppTheme.primaryRed,
              ),
              _buildStatCard(
                Icons.eco,
                '${(cigarettesNotSmoked * 0.014).toStringAsFixed(1)} kg',
                'Azalan CO2',
                Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health Timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sağlık İyileşme Zaman Çizelgesi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeline('20 dakika', 'Nabız ve tansiyon normalleşir', days >= 0, Icons.monitor_heart),
                  _buildTimeline('12 saat', 'Kandaki CO seviyesi normale döner', diff.inHours >= 12, Icons.air),
                  _buildTimeline('2 hafta', 'Akciğer fonksiyonları iyileşmeye başlar', days >= 14, Icons.healing),
                  _buildTimeline('1 ay', 'Öksürük ve nefes darlığı azalır', days >= 30, Icons.masks),
                  _buildTimeline('1 yıl', 'Kalp hastalığı riski yarıya düşer', days >= 365, Icons.favorite),
                  _buildTimeline('5 yıl', 'İnme riski sigara içmeyenlerle eşitlenir', days >= 1825, Icons.psychology),
                  _buildTimeline('10 yıl', 'Akciğer kanseri riski yarıya düşer', days >= 3650, Icons.local_hospital),
                  _buildTimeline('15 yıl', 'Kalp hastalığı riski hiç içmemiş gibi olur', days >= 5475, Icons.celebration),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(String time, String desc, bool achieved, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: achieved ? Colors.teal : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achieved ? Icons.check : icon,
              color: achieved ? Colors.white : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: achieved ? Colors.teal : AppTheme.textLight,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: achieved ? AppTheme.textDark : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
