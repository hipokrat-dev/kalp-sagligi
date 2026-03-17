import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _emailSent = false;
  late AnimationController _checkAnimController;
  late Animation<double> _checkScaleAnim;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _checkAnimController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final result = await AuthService.instance.resetPassword(
      email: _emailController.text,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result.success) {
      setState(() => _emailSent = true);
      _checkAnimController.forward(from: 0);
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
        title: Text('Sifre Sifirla', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _emailSent ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Animated check circle
        AnimatedBuilder(
          animation: _checkScaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _checkScaleAnim.value,
            child: child,
          ),
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadow(const Color(0xFF66BB6A)),
            ),
            child: const Icon(Icons.mark_email_read_rounded, size: 44, color: Colors.white),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'E-posta Gonderildi!',
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Text(
            '${_emailController.text} adresine sifre sifirlama baglantisi gonderildi.\n\n'
            'E-postanizi kontrol edin ve baglantiya tiklayarak yeni sifrenizi belirleyin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 28),
        // Gradient button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient2,
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
            ),
            child: Center(
              child: Text('Giris Sayfasina Don', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _emailSent = false;
          }),
          child: Text('Farkli e-posta dene', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient2,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.softShadow(AppTheme.primaryRed),
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Sifrenizi Sifirlayin',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'E-posta adresinize sifre sifirlama baglantisi gonderecegiz',
            style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w500, height: 1.4),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
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
          const SizedBox(height: 28),

          // Gradient send button
          GestureDetector(
            onTap: _loading ? null : _resetPassword,
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
                    : Text('Sifirlama Baglantisi Gonder', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
