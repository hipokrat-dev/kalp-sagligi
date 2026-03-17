import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class AlarmOverlay extends StatefulWidget {
  final AlarmData alarm;
  final VoidCallback onDismiss;
  final VoidCallback? onDisableType;
  const AlarmOverlay({super.key, required this.alarm, required this.onDismiss, this.onDisableType});

  @override
  State<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<AlarmOverlay> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();

    // 30 second auto-dismiss countdown
    _countdownController = AnimationController(vsync: this, duration: const Duration(seconds: 30));
    _countdownController.forward();
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _dismiss();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    if (!mounted) return;
    await _entryController.reverse();
    widget.onDismiss();
  }

  void _snooze(int minutes) async {
    await _entryController.reverse();
    AlarmService.instance.snoozeAlarm(widget.alarm, minutes: minutes);
    widget.onDismiss();
  }

  void _disableAndDismiss() async {
    await _entryController.reverse();
    widget.onDisableType?.call();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.alarm.color;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Gradient backdrop
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Ripple waves behind card
            Center(child: _RippleWaves(color: color)),

            // Main card
            SafeArea(
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 50, offset: const Offset(0, 16)),
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gradient header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          child: Column(
                            children: [
                              _BouncingIcon(icon: widget.alarm.icon),
                              const SizedBox(height: 14),
                              Text(
                                widget.alarm.title,
                                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Countdown bar
                              AnimatedBuilder(
                                animation: _countdownController,
                                builder: (_, __) => ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: 1.0 - _countdownController.value,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                          child: Column(
                            children: [
                              Text(
                                widget.alarm.message,
                                style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textLight, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Action buttons
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _dismiss,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: Text('Tamam', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Snooze buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _snooze(5),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text('5 dk ertele',
                                          style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _snooze(15),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('15 dk ertele',
                                          style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Disable
                              if (widget.onDisableType != null)
                                TextButton(
                                  onPressed: _disableAndDismiss,
                                  child: Text('Bu hatırlatmayı kapat',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouncing Icon ──

class _BouncingIcon extends StatefulWidget {
  final IconData icon;
  const _BouncingIcon({required this.icon});

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final bounce = math.sin(_controller.value * math.pi) * 6;
        final scale = 1.0 + math.sin(_controller.value * math.pi) * 0.1;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, size: 36, color: Colors.white),
      ),
    );
  }
}

// ── Ripple Waves ──

class _RippleWaves extends StatefulWidget {
  final Color color;
  const _RippleWaves({required this.color});

  @override
  State<_RippleWaves> createState() => _RippleWavesState();
}

class _RippleWavesState extends State<_RippleWaves> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: _RipplePainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final p = (progress + i * 0.33) % 1.0;
      final radius = p * size.width / 2;
      final opacity = (1.0 - p) * 0.15;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.progress != progress;
}
