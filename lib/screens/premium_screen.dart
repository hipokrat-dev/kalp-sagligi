import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = false;
  int _selectedPlan = 0; // 0=monthly, 1=yearly

  void _purchase() async {
    setState(() => _loading = true);
    final success = _selectedPlan == 0
        ? await PremiumService.instance.purchaseMonthly()
        : await PremiumService.instance.purchaseYearly();
    setState(() => _loading = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textDark),
                    ),
                  ),
                ),
              ),

              // Header
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow(const Color(0xFFFFA000)),
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 42, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                ).createShader(bounds),
                child: Text('Premium', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text('Tum ozelliklerin kilidini ac', style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 15)),
              const SizedBox(height: 28),

              // Features
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.people_rounded, 'Arkadas sistemi', 'Arkadaslarinla sagligi birlikte takip et'),
                    _buildFeatureRow(Icons.emoji_events_rounded, 'Challenge yarismalar', 'Arkadaslarinla haftalik yarismalara katil'),
                    _buildFeatureRow(Icons.notifications_active_rounded, 'Sinirsiz hatirlatma', 'Diledigin kadar hatirlatma ayarla'),
                    _buildFeatureRow(Icons.history_rounded, 'Sinirsiz gecmis', 'Tum saglik verilerine eris (365 gun)'),
                    _buildFeatureRow(Icons.shield_rounded, 'Detayli risk analizi', 'Kapsamli kalp sagligi degerlendirmesi'),
                    _buildFeatureRow(Icons.auto_graph_rounded, 'Gelismis istatistikler', 'Haftalik ve aylik trend grafikleri'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Plan selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _buildPlanCard(0, 'Aylik', '\$2.99', '/ay', null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPlanCard(1, 'Yillik', '\$19.99', '/yil', '%44 tasarruf')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Purchase button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _loading ? null : _purchase,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _loading
                          ? null
                          : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                      color: _loading ? Colors.grey.shade300 : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _loading ? null : AppTheme.softShadow(const Color(0xFFFFA000)),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Premium\'a Gec',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Restore
              TextButton(
                onPressed: () async {
                  await PremiumService.instance.restorePurchases();
                  if (mounted && PremiumService.instance.isPremium) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text('Satin alimi geri yukle', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 13)),
              ),

              // Terms
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Text(
                  'Abonelik otomatik yenilenir. Istediginiz zaman Google Play\'den iptal edebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFFA000), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFA000), size: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, String name, String price, String period, String? badge) {
    final selected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFFA000) : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFFFFA000).withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))]
              : AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
            ],
            Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textLight, fontSize: 13)),
            const SizedBox(height: 4),
            Text(price, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            Text(period, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight)),
            const SizedBox(height: 8),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFFFA000) : AppTheme.inputFill,
                border: selected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }
}
