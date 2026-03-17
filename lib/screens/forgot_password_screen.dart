import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _securityQuestion;
  bool _userFound = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _findUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı girin'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final question = await AuthService.instance.getSecurityQuestion(username);
    setState(() => _loading = false);

    if (!mounted) return;

    if (question != null) {
      setState(() {
        _securityQuestion = question;
        _userFound = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bulunamadı'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await AuthService.instance.resetPassword(
      username: _usernameController.text,
      securityAnswer: _answerController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre başarıyla sıfırlandı! Giriş yapabilirsiniz.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Sıfırla')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_reset, size: 48, color: AppTheme.primaryRed),
              const SizedBox(height: 12),
              const Text(
                'Şifrenizi Sıfırlayın',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Güvenlik sorunuzu cevaplayarak yeni şifre belirleyin',
                style: TextStyle(color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),

              // Username
              TextFormField(
                controller: _usernameController,
                enabled: !_userFound,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: !_userFound
                      ? null
                      : const Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
              const SizedBox(height: 12),

              if (!_userFound) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _findUser,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Kullanıcıyı Bul'),
                  ),
                ),
              ],

              if (_userFound) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: Colors.orange, size: 18),
                          SizedBox(width: 6),
                          Text('Güvenlik Sorusu',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _securityQuestion!,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _answerController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Cevabınız',
                    prefixIcon: Icon(Icons.question_answer_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Cevap gerekli';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'En az 4 karakter',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 4) return 'Şifre en az 4 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _newPasswordController.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _resetPassword,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Şifreyi Sıfırla', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
