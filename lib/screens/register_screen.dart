import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await AuthService.instance.register(
      displayName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayit basarili! Hos geldiniz.', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hesap Olustur', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text('Saglik verilerinizi guvenle takip edin', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),

              // Ad Soyad
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 2) return 'Ad en az 2 karakter olmali';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // E-posta
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                  if (!v.contains('@')) return 'Gecerli bir e-posta girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sifre
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Sifre',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  hintText: 'En az 6 karakter',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Sifre en az 6 karakter olmali';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sifre Tekrar
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'Sifre Tekrar',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return 'Sifreler eslesmiyor';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Gradient register button
              GestureDetector(
                onTap: _loading ? null : _register,
                child: Container(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: _loading ? null : AppTheme.primaryGradient2,
                    color: _loading ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    boxShadow: _loading ? null : AppTheme.softShadow(AppTheme.primaryRed),
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Kayit Ol', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
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
