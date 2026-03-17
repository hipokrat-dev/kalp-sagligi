import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  String _selectedQuestion = 'İlk evcil hayvanınızın adı nedir?';
  final _securityQuestions = [
    'İlk evcil hayvanınızın adı nedir?',
    'Annenizin kızlık soyadı nedir?',
    'İlk okulunuzun adı nedir?',
    'En sevdiğiniz yemek nedir?',
    'Doğduğunuz şehir neresidir?',
    'En yakın arkadaşınızın adı nedir?',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await AuthService.instance.register(
      username: _usernameController.text,
      password: _passwordController.text,
      securityQuestion: _selectedQuestion,
      securityAnswer: _securityAnswerController.text,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Hoş geldiniz.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
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
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hesap Oluştur',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Sağlık verilerinizi güvenle takip edin',
                style: TextStyle(color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),

              // Username
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'En az 3 karakter',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'Kullanıcı adı en az 3 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'En az 4 karakter',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 4) return 'Şifre en az 4 karakter olmalı';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Security Question Section
              Container(
                padding: const EdgeInsets.all(16),
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
                        Icon(Icons.security, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Güvenlik Sorusu',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Şifrenizi unuttuğunuzda bu soru ile sıfırlayabilirsiniz',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedQuestion,
                      decoration: const InputDecoration(
                        labelText: 'Güvenlik Sorusu',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _securityQuestions.map((q) {
                        return DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedQuestion = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _securityAnswerController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Cevabınız',
                        prefixIcon: Icon(Icons.question_answer_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Güvenlik cevabı gerekli';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Kayıt Ol', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
