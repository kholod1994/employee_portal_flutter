import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/storage/safe_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/portal_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _arcProgress;
  late final Animation<double> _sparkleScale;
  late final Animation<double> _sparkleRotation;
  late final Animation<double> _taglineFade;
  late final Animation<double> _ambientGlow;

  final _storage = const SafeStorage();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 1. Logo fades and scales in gently
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.35, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Glowing orbital arc sweeps across the top from left to right
    _arcProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.20, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Sparkle / Starburst flares up as the comet reaches the right apex
    _sparkleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.68, 0.95),
      ),
    );

    _sparkleRotation = Tween<double>(begin: 0.0, end: math.pi / 2).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
      ),
    );

    // 4. Tagline fades in smoothly after arc starts
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOut),
      ),
    );

    // 5. Ambient breathing glow behind the logo
    _ambientGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 0.85), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 0.55), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.90, curve: Curves.easeInOutSine),
      ),
    );

    _mainController.forward();

    // Check auth and transition to appropriate screen
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  Future<void> _navigateNext() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    try {
      final rememberMe = await _storage.read(key: 'rememberMe');
      final identifier = await _storage.read(key: 'employeeNumber');
      final password = await _storage.read(key: 'password');

      if (!mounted) return;

      Widget destination;
      if (rememberMe == 'true' && identifier != null && password != null) {
        final provider = context.read<PortalProvider>();
        final loginRes = await provider.login(
          identifier: identifier,
          password: password,
        );
        destination = (loginRes['success'] == true)
            ? const HomeScreen()
            : const LoginScreen();
      } else {
        destination = const LoginScreen();
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            );
          },
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF06101D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep luxury midnight twilight gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.1),
                radius: 1.1,
                colors: [
                  Color(0xFF0F2B48),
                  Color(0xFF0A1B2E),
                  Color(0xFF050D18),
                  Color(0xFF02070D),
                ],
                stops: [0.0, 0.45, 0.8, 1.0],
              ),
            ),
          ),

          // 2. Ambient background stars & twinkling particles
          RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: const _BackgroundStarsPainter(),
            ),
          ),

          // 3. Central Logo, Animated Arc & Typography
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Combined Logo + Orbital Arc Stage
                    SizedBox(
                      width: 320,
                      height: 180,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Soft pulsing ambient glow behind logo
                          Positioned(
                            top: 40,
                            child: Container(
                              width: 170,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2DD4BF)
                                        .withValues(alpha: 0.18 * _ambientGlow.value),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.14 * _ambientGlow.value),
                                    blurRadius: 90,
                                    spreadRadius: 35,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Al-Dallel Emblem (White AR Mark)
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoFade.value,
                              child: Image.asset(
                                'assets/images/logo_dallel_white.png',
                                width: 140,
                                height: 95,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback if asset isn't ready
                                  return const Icon(
                                    Icons.business_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Dynamic Orbital Arc & Flying Comet / Starburst Painter
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _OrbitalArcPainter(
                                progress: _arcProgress.value,
                                sparkleScale: _sparkleScale.value,
                                sparkleRotation: _sparkleRotation.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Brand Typography: الدليل
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Column(
                          children: [
                            Text(
                              'الدليل',
                              style: GoogleFonts.cairo(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'شركة الدليل الرقمي',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE2E8F0),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle / Tagline ("لتقنية المعلومات والنظم الجغرافية")
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1.0 - _taglineFade.value)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'لتقنية المعلومات والنظم الجغرافية',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom subtle branding / version
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: _taglineFade.value * 0.7,
                child: Text(
                  'AL DALEEL FOR IT & GIS • V${AppConfig.appVersion}',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter that accurately reproduces the glowing orbital arc,
/// flying comet/particle tip, and brilliant lens flare sparkle from the video.
class _OrbitalArcPainter extends CustomPainter {
  final double progress;
  final double sparkleScale;
  final double sparkleRotation;

  _OrbitalArcPainter({
    required this.progress,
    required this.sparkleScale,
    required this.sparkleRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Define the elegant orbital arc over the logo
    // Left start -> Apex top-center -> Right landing apex
    final startPoint = Offset(center.dx - 128, center.dy + 12);
    final controlPoint1 = Offset(center.dx - 70, center.dy - 78);
    final controlPoint2 = Offset(center.dx + 50, center.dy - 82);
    final endPoint = Offset(center.dx + 118, center.dy - 12);

    final fullPath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

    // Extract animated portion of the path
    final pathMetrics = fullPath.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final totalLength = metric.length;
    final currentLength = totalLength * progress.clamp(0.0, 1.0);
    final animatedPath = metric.extractPath(0.0, currentLength);

    // 1. Draw glowing background blur of the arc
    final outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(animatedPath, outerGlowPaint);

    final midGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(animatedPath, midGlowPaint);

    // 2. Draw crisp core glowing beam with gradient shader
    final tangent = metric.getTangentForOffset(currentLength);
    final currentPos = tangent?.position ?? endPoint;

    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        startPoint,
        currentPos,
        [
          const Color(0xFF2DD4BF).withValues(alpha: 0.0),
          const Color(0xFF2DD4BF).withValues(alpha: 0.5),
          const Color(0xFF67E8F9),
          Colors.white,
        ],
        [0.0, 0.45, 0.85, 1.0],
      );
    canvas.drawPath(animatedPath, beamPaint);

    // 3. Draw flying glowing comet / jet particle at the tip while in flight
    if (progress > 0.05 && progress < 0.95 && tangent != null) {
      final angle = tangent.angle;
      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(angle);

      // Jet / Comet glow head
      final headGlow = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset.zero, 3.5, headGlow);

      // Miniature flying streak/jet icon
      final jetPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final jetPath = Path()
        ..moveTo(5.0, 0)
        ..lineTo(-4.0, -3.0)
        ..lineTo(-2.0, 0)
        ..lineTo(-4.0, 3.0)
        ..close();
      canvas.drawPath(jetPath, jetPaint);

      canvas.restore();
    }

    // 4. Draw brilliant lens flare starburst at the landing apex
    if (sparkleScale > 0.01) {
      _drawStarburst(canvas, endPoint, sparkleScale, sparkleRotation);
    }
  }

  void _drawStarburst(Canvas canvas, Offset center, double scale, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // A. Soft radial flare corona
    final coronaPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset.zero, 18, coronaPaint);

    // B. Horizontal anamorphic lens flare beam
    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-45, 0),
        const Offset(45, 0),
        [
          Colors.white.withValues(alpha: 0.0),
          const Color(0xFF67E8F9).withValues(alpha: 0.7),
          Colors.white,
          const Color(0xFF67E8F9).withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.0),
        ],
        [0.0, 0.35, 0.5, 0.65, 1.0],
      )
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-45, 0), const Offset(45, 0), beamPaint);

    // C. 4-Point Diamond Sparkle Star (Primary Cross)
    canvas.rotate(rotation);

    final starPath = Path();
    const double radius = 22.0;
    const double inner = 3.2;

    starPath.moveTo(0, -radius);
    starPath.quadraticBezierTo(0, 0, inner, 0);
    starPath.quadraticBezierTo(0, 0, radius, 0);
    starPath.quadraticBezierTo(0, 0, 0, inner);
    starPath.quadraticBezierTo(0, 0, 0, radius);
    starPath.quadraticBezierTo(0, 0, -inner, 0);
    starPath.quadraticBezierTo(0, 0, -radius, 0);
    starPath.quadraticBezierTo(0, 0, 0, -inner);
    starPath.close();

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);

    // D. 4-Point Secondary Diagonal Rays (rotated 45 deg)
    canvas.rotate(math.pi / 4);
    final diagStarPath = Path();
    const double diagRadius = 11.0;
    const double diagInner = 2.0;

    diagStarPath.moveTo(0, -diagRadius);
    diagStarPath.quadraticBezierTo(0, 0, diagInner, 0);
    diagStarPath.quadraticBezierTo(0, 0, diagRadius, 0);
    diagStarPath.quadraticBezierTo(0, 0, 0, diagInner);
    diagStarPath.quadraticBezierTo(0, 0, 0, diagRadius);
    diagStarPath.quadraticBezierTo(0, 0, -diagInner, 0);
    diagStarPath.quadraticBezierTo(0, 0, -diagRadius, 0);
    diagStarPath.quadraticBezierTo(0, 0, 0, -diagInner);
    diagStarPath.close();

    final diagPaint = Paint()
      ..color = const Color(0xFF67E8F9).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(diagStarPath, diagPaint);

    // E. Intense white center core
    canvas.drawCircle(Offset.zero, 2.5, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitalArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sparkleScale != sparkleScale ||
        oldDelegate.sparkleRotation != sparkleRotation;
  }
}

/// Subtle static twinkling ambient stars painter for the deep space background.
class _BackgroundStarsPainter extends CustomPainter {
  const _BackgroundStarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = 0.5 + rand.nextDouble() * 1.2;
      final alpha = 0.15 + rand.nextDouble() * 0.45;

      starPaint.color = (i % 3 == 0)
          ? const Color(0xFF2DD4BF).withValues(alpha: alpha)
          : Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

