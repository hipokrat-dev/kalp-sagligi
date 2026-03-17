import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _username = AuthService.instance.currentUsername ?? '';
  }

  void _changeUsername() async {
    final controller = TextEditingController(text: _username);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcı Adını Değiştir'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Yeni kullanıcı adı',
            prefixIcon: Icon(Icons.person_outline),
            hintText: 'En az 3 karakter',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      final res = await AuthService.instance.changeUsername(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: res.success ? Colors.green : AppTheme.primaryRed,
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
        title: const Text('Şifre Değiştir'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: Icon(Icons.lock),
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
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) {
                    if (v != newCtrl.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Değiştir'),
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
            content: Text(res.message),
            backgroundColor: res.success ? Colors.green : AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      AuthService.instance.logout();
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
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kalp Sağlığı Kullanıcısı',
                          style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Settings
          const Text(
            'Hesap Ayarları',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppTheme.primaryRed),
                  title: const Text('Kullanıcı Adını Değiştir'),
                  subtitle: Text(_username),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeUsername,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppTheme.primaryRed),
                  title: const Text('Şifre Değiştir'),
                  subtitle: const Text('Hesap şifrenizi güncelleyin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppTheme.primaryRed),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(color: AppTheme.primaryRed, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                const Icon(Icons.favorite, color: AppTheme.primaryRed, size: 28),
                const SizedBox(height: 4),
                const Text(
                  'Kalp Sağlığı v1.0',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Verileriniz cihazınızda güvenle saklanır',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
