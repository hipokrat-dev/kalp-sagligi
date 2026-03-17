import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Sigara Birakma Sayaci', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bugun sigarayi birakiyorsun! Bilgilerini gir:', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppTheme.textLight)),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                labelText: 'Gunluk sigara sayisi',
                suffixText: 'adet',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                labelText: 'Paket fiyati',
                suffixText: 'TL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Basla', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Sayaci Sifirla', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Sayaci sifirlamak istediginize emin misiniz?', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: Text('Sifirla', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Sigara Birakma', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.tealGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow(const Color(0xFF26A69A)),
                  ),
                  child: const Icon(Icons.smoke_free, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 28),
                Text(
                  'Sigarayi Birakmaya Hazir misin?',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sigara birakma sayacini baslatarak ilerlemenizi takip edin. '
                  'Ne kadar para biriktirdiginizi ve sagliginiza katkisini gorun.',
                  style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _startCounter,
                  child: Container(
                    width: double.infinity,
                    height: AppTheme.buttonHeight,
                    decoration: BoxDecoration(
                      gradient: AppTheme.tealGradient,
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                      boxShadow: AppTheme.softShadow(const Color(0xFF26A69A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Sayaci Baslat', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
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
    final minutesOfLife = cigarettesNotSmoked * 11;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Sigara Birakma', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        actions: [
          GestureDetector(
            onTap: _resetCounter,
            child: Container(
              width: 40, height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.refresh_rounded, color: AppTheme.textDark, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Hero counter card with gradient
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppTheme.tealGradient,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.softShadow(const Color(0xFF26A69A)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.smoke_free_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  'SIGARASIZ GECIRDIGIN SURE',
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  '$days gun $hours saat $minutes dakika',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Baslangic: ${_quitDate!.day}/${_quitDate!.month}/${_quitDate!.year}',
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid as gradient mini cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                Icons.savings_rounded,
                '${moneySaved.toStringAsFixed(0)} TL',
                'Biriken Para',
                const [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
              ),
              _buildStatCard(
                Icons.smoke_free_rounded,
                '$cigarettesNotSmoked',
                'Icilmeyen Sigara',
                const [Color(0xFFFF9800), Color(0xFFFFB74D)],
              ),
              _buildStatCard(
                Icons.favorite_rounded,
                '${(minutesOfLife / 60).toStringAsFixed(0)} saat',
                'Kazanilan Omur',
                const [Color(0xFFE53935), Color(0xFFFF6B6B)],
              ),
              _buildStatCard(
                Icons.eco_rounded,
                '${(cigarettesNotSmoked * 0.014).toStringAsFixed(1)} kg',
                'Azalan CO2',
                const [Color(0xFF26A69A), Color(0xFF80CBC4)],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Health Timeline
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
                Text('SAGLIK IYILESME ZAMAN CIZELGESI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
                const SizedBox(height: 18),
                _buildTimeline('20 dakika', 'Nabiz ve tansiyon normallesir', days >= 0, Icons.monitor_heart_rounded, isFirst: true),
                _buildTimeline('12 saat', 'Kandaki CO seviyesi normale doner', diff.inHours >= 12, Icons.air_rounded),
                _buildTimeline('2 hafta', 'Akciger fonksiyonlari iyilesmeye baslar', days >= 14, Icons.healing_rounded),
                _buildTimeline('1 ay', 'Oksuruk ve nefes darligi azalir', days >= 30, Icons.masks_rounded),
                _buildTimeline('1 yil', 'Kalp hastaligi riski yariya duser', days >= 365, Icons.favorite_rounded),
                _buildTimeline('5 yil', 'Inme riski sigara icmeyenlerle esitlenir', days >= 1825, Icons.psychology_rounded),
                _buildTimeline('10 yil', 'Akciger kanseri riski yariya duser', days >= 3650, Icons.local_hospital_rounded),
                _buildTimeline('15 yil', 'Kalp hastaligi riski hic icmemis gibi olur', days >= 5475, Icons.celebration_rounded, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildTimeline(String time, String desc, bool achieved, IconData icon, {bool isFirst = false, bool isLast = false}) {
    final tealColor = const Color(0xFF26A69A);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: achieved
                          ? LinearGradient(colors: [tealColor, tealColor.withValues(alpha: 0.5)])
                          : null,
                      color: achieved ? null : Colors.grey.shade200,
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: achieved ? AppTheme.tealGradient : null,
                    color: achieved ? null : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    boxShadow: achieved
                        ? [BoxShadow(color: tealColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Icon(
                    achieved ? Icons.check_rounded : icon,
                    color: achieved ? Colors.white : Colors.grey.shade400,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: achieved
                            ? LinearGradient(
                                colors: [tealColor.withValues(alpha: 0.5), tealColor.withValues(alpha: 0.15)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: achieved ? null : Colors.grey.shade200,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: achieved ? tealColor : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: achieved ? AppTheme.textDark : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
