import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import '../screens/premium_screen.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final bool featureEnabled;
  final String featureName;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureEnabled,
    this.featureName = 'Bu ozellik',
  });

  @override
  Widget build(BuildContext context) {
    if (featureEnabled) return child;

    return Stack(
      children: [
        // Blurred/dimmed content
        IgnorePointer(
          child: Opacity(opacity: 0.3, child: child),
        ),
        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _showPremiumDialog(context),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text('Premium', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPremiumDialog(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
  }
}

// Small lock badge for nav items, buttons etc
class PremiumBadge extends StatelessWidget {
  final Widget child;
  final bool show;
  const PremiumBadge({super.key, required this.child, this.show = true});

  @override
  Widget build(BuildContext context) {
    if (!show || PremiumService.instance.isPremium) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 8),
          ),
        ),
      ],
    );
  }
}
