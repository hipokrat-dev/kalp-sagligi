import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await AuthService.instance.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gradient circle logo
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient2,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.primaryGradient2.createShader(bounds),
                    child: Text(
                      'Kalp Sagligi',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Sagliginiz elinizde', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),

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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Sifre',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Sifre gerekli';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: Text('Sifremi Unuttum', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gradient login button
                  GestureDetector(
                    onTap: _loading ? null : _login,
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
                            : Text('Giris Yap', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hesabiniz yok mu? ', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                      TextButton(
                        onPressed: () async {
                          final registered = await Navigator.push<bool>(
                            context, MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                          if (registered == true && context.mounted) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
                          }
                        },
                        child: Text('Kayit Ol', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
