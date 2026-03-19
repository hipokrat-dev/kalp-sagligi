import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/health_connect_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'reminder_settings_screen.dart';
import 'friends_screen.dart';
import 'challenges_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _username = '';
  bool _healthConnectAvailable = false;
  bool _healthConnectEnabled = false;

  @override
  void initState() {
    super.initState();
    _username = AuthService.instance.currentUsername ?? '';
    _loadHealthConnect();
  }

  Future<void> _loadHealthConnect() async {
    final available = await HealthConnectService.instance.checkAvailability();
    final enabled = await StorageService.instance.getHealthConnectEnabled();
    if (mounted) {
      setState(() {
        _healthConnectAvailable = available;
        _healthConnectEnabled = enabled && available;
      });
    }
  }

  void _toggleHealthConnect(bool value) async {
    if (value) {
      final granted = await HealthConnectService.instance.requestPermissions();
      if (granted) {
        await StorageService.instance.setHealthConnectEnabled(true);
        if (mounted) setState(() => _healthConnectEnabled = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Health Connect izni verilmedi', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              backgroundColor: AppTheme.primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      await StorageService.instance.setHealthConnectEnabled(false);
      if (mounted) setState(() => _healthConnectEnabled = false);
    }
  }

  void _changeUsername() async {
    final controller = TextEditingController(text: _username);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Kullanici Adini Degistir', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            labelText: 'Yeni kullanici adi',
            prefixIcon: Icon(Icons.person_outline_rounded),
            hintText: 'En az 3 karakter',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      final res = await AuthService.instance.changeUsername(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: res.success ? Colors.green : AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (res.success) {
          setState(() => _username = result.trim());
        }
      }
    }
  }

  void _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Sifre Degistir', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Sifre',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Yeni Sifre',
                    prefixIcon: Icon(Icons.lock_rounded),
                    hintText: 'En az 4 karakter',
                  ),
                  validator: (v) {
                    if (v == null || v.length < 4) return 'En az 4 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Yeni Sifre Tekrar',
                    prefixIcon: Icon(Icons.lock_rounded),
                  ),
                  validator: (v) {
                    if (v != newCtrl.text) return 'Sifreler eslesmiyor';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text('Degistir', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final res = await AuthService.instance.changePassword(
        currentPassword: currentCtrl.text,
        newPassword: newCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: res.success ? Colors.green : AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: Text('Cikis Yap', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Hesabinizdan cikis yapmak istediginize emin misiniz?', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: Text('Cikis Yap', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.instance.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Ayarlar', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Profile Card with gradient avatar background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient2,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
                  ),
                  child: Center(
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AuthService.instance.currentEmail ?? 'Kalp Sagligi Kullanicisi',
                        style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Settings
          Text('HESAP AYARLARI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppTheme.primaryRed,
                  title: 'Kullanici Adini Degistir',
                  subtitle: _username,
                  onTap: _changeUsername,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                ),
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppTheme.primaryRed,
                  title: 'Sifre Degistir',
                  subtitle: 'Hesap sifrenizi guncelleyin',
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Social
          Text('SOSYAL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.people_rounded,
                  iconColor: const Color(0xFF42A5F5),
                  title: 'Arkadaslar',
                  subtitle: 'Arkadas ekle ve saglik verilerini paylas',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
                ),
                const Divider(height: 1, indent: 60),
                _buildSettingTile(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFFF9800),
                  title: 'Challenge Yarismalari',
                  subtitle: 'Arkadaslarinla saglik yarismasi olustur',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Health & Reminders
          Text('SAGLIK & HATIRLATMALAR', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textLight, letterSpacing: 1)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.notifications_active_rounded,
                  iconColor: Colors.orange,
                  title: 'Hatirlatma Ayarlari',
                  subtitle: 'Su, hareket, tansiyon hatirlatmalari',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SwitchListTile(
                    secondary: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (_healthConnectAvailable ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: _healthConnectAvailable ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text('Google Health Connect', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark)),
                    subtitle: Text(
                      _healthConnectAvailable
                          ? (_healthConnectEnabled ? 'Bagli - adimlar otomatik cekilir' : 'Adim sayaci baglantisi')
                          : 'Bu cihazda kullanilamiyor',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                    ),
                    value: _healthConnectEnabled,
                    activeThumbColor: Colors.green,
                    activeTrackColor: Colors.green.withValues(alpha: 0.3),
                    inactiveTrackColor: AppTheme.inputFill,
                    onChanged: _healthConnectAvailable ? _toggleHealthConnect : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          GestureDetector(
            onTap: _logout,
            child: Container(
              width: double.infinity,
              height: AppTheme.buttonHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: AppTheme.primaryRed, size: 20),
                  const SizedBox(width: 8),
                  Text('Cikis Yap', style: GoogleFonts.inter(color: AppTheme.primaryRed, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient2.createShader(bounds),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kalp Sagligi v1.0',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                ),
                Text(
                  'Verileriniz cihazinizda guvenle saklanir',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
