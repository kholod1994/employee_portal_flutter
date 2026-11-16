import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/storage/safe_storage.dart';
import '../providers/portal_provider.dart';
import '../services/app_notification_service.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  final _storage = const SafeStorage();

  bool _canBiometric = false;
  String _biometricLabel = 'البصمة أو الوجه';
  bool _isBiometricLoading = false;

  late final AnimationController _flightAnimController;

  @override
  void initState() {
    super.initState();
    _flightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _loadSavedCredentials();
    _checkBiometric();
  }

  @override
  void dispose() {
    _flightAnimController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    try {
      final canAuth = await BiometricService.canAuthenticate();
      final label = await BiometricService.getBiometricLabel();
      if (mounted) {
        setState(() {
          _canBiometric = canAuth;
          _biometricLabel = label;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedCredentials() async {
    final identifier = await _storage.read(key: 'employeeNumber');
    final password = await _storage.read(key: 'password');
    final rememberMe = await _storage.read(key: 'rememberMe');

    if (!mounted) return;
    if (rememberMe == 'true' && identifier != null && password != null) {
      setState(() {
        _identifierController.text = identifier;
        _passwordController.text = password;
        _rememberMe = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleLogin();
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isBiometricLoading = true);
    try {
      final authenticated = await BiometricService.authenticate(
        localizedReason: 'سجل الدخول باستخدام $_biometricLabel',
      );
      if (!authenticated) {
        setState(() => _isBiometricLoading = false);
        return;
      }

      final creds = await BiometricService.getSavedCredentials();
      if (creds == null) {
        setState(() => _isBiometricLoading = false);
        _showMessage('يرجى تسجيل الدخول أولاً لتفعيل البصمة تلقائياً');
        return;
      }

      _identifierController.text = creds['identifier']!;
      _passwordController.text = creds['password']!;
      setState(() => _isBiometricLoading = false);
      await _handleLogin();
    } catch (e) {
      setState(() => _isBiometricLoading = false);
      _showMessage('حدث خطأ أثناء المصادقة الحيوية');
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _storage.write(
        key: 'employeeNumber',
        value: _identifierController.text.trim(),
      );
      await _storage.write(key: 'password', value: _passwordController.text);
      await _storage.write(key: 'rememberMe', value: 'true');
    } else {
      await _storage.delete(key: 'employeeNumber');
      await _storage.delete(key: 'password');
      await _storage.write(key: 'rememberMe', value: 'false');
    }
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('يرجى إدخال البريد الإلكتروني أو الرقم الوظيفي وكلمة المرور');
      return;
    }

    final provider = context.read<PortalProvider>();
    final result = await provider.login(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      await _saveCredentials();
      final isBioEnabled = await BiometricService.isBiometricEnabled();
      if (isBioEnabled) {
        await BiometricService.saveCredentials(identifier, password);
      }
      await AppNotificationService.requestPermission();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showMessage(result['error'] ?? 'فشل تسجيل الدخول. تحقق من البيانات المدخلة');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final size = MediaQuery.of(context).size;
    final topBannerHeight = math.min(size.height * 0.38, 300.0);
    final isLoading = provider.isLoading || _isBiometricLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F0F8),
      body: Stack(
        children: [
          // 1. Scenic Mountain & Travel Landscape Header (matches video top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBannerHeight + 40,
            child: const _TravelScenicHeader(),
          ),

          // 2. Main Scrollable Content Overlapping the Banner
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: topBannerHeight),

                  // 3. Rounded White Card Sheet (matches video card)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 520),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A0F172A),
                          blurRadius: 30,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(26, 32, 26, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title: Welcome back / مرحباً بك مجدداً
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'مرحباً بك مجدداً',
                                style: GoogleFonts.cairo(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'سجل دخولك لمتابعة الحضور، الرواتب والطلبات',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Input 1: Email or Employee Number
                        _buildInputField(
                          controller: _identifierController,
                          hint: 'البريد الإلكتروني أو الرقم الوظيفي',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 14),

                        // Input 2: Password with eye toggle
                        _buildInputField(
                          controller: _passwordController,
                          hint: 'أدخل كلمة المرور',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Remember me checkbox & Forgot password row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      activeColor: const Color(0xFF1E3A8A),
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تذكر بياناتي',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _showMessage(
                                  'لإعادة تعيين كلمة المرور، يرجى التواصل مع إدارة الموارد البشرية أو قسم الدعم',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'نسيت كلمة المرور؟',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Primary Action Button: Login (Deep Royal Blue Gradient)
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isLoading ? null : _handleLogin,
                              child: Center(
                                child: Text(
                                  'تسجيل الدخول',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Biometric Quick Login Button (if available)
                        if (_canBiometric) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'أو المتابعة السريعة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isLoading ? null : _handleBiometricLogin,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _biometricLabel.contains('الوجه')
                                          ? Icons.face_rounded
                                          : Icons.fingerprint_rounded,
                                      color: const Color(0xFF1E3A8A),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'الدخول بـ $_biometricLabel',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Footer branding
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'شركة الدليل الرقمي لتقنية المعلومات والنظم الجغرافية',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppConfig.displayVersion,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Frosted Glass Loading Overlay (Frame 14s in the video)
          if (isLoading)
            Positioned.fill(
              child: _FlightLoadingOverlay(
                controller: _flightAnimController,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? obscureText : false,
              keyboardType: keyboardType,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: onToggleVisibility,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Custom scenic painter for the top section matching the video illustration:
/// Soft layered mountains, distant peaks, clouds, sun glow and modern corporate wayfinding badge.
class _TravelScenicHeader extends StatelessWidget {
  const _TravelScenicHeader();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScenicPainter(),
      child: Container(),
    );
  }
}

class _ScenicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          const Color(0xFFB5CCE2),
          const Color(0xFFD3E2F0),
          const Color(0xFFE8F1F8),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, skyPaint);

    // 2. Soft Sun / Glow in upper right
    final sunGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.22), 55, sunGlow);

    final sunCore = Paint()..color = const Color(0xFFFFF7ED).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.22), 26, sunCore);

    // 3. Floating Clouds
    _drawCloud(canvas, Offset(size.width * 0.20, size.height * 0.18), 34);
    _drawCloud(canvas, Offset(size.width * 0.85, size.height * 0.12), 26);

    // 4. Distant Mountain Ridge (Soft lavender/blue)
    final distantPeak = Path()
      ..moveTo(0, size.height * 0.65)
      ..lineTo(size.width * 0.25, size.height * 0.38)
      ..lineTo(size.width * 0.50, size.height * 0.60)
      ..lineTo(size.width * 0.78, size.height * 0.35)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final distantPaint = Paint()..color = const Color(0xFFA2BCD5);
    canvas.drawPath(distantPeak, distantPaint);

    // 5. Midground Mountain Ridge
    final midPeak = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.38, size.height * 0.46)
      ..lineTo(size.width * 0.65, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final midPaint = Paint()..color = const Color(0xFF7D9FB/255 != 0 ? 0xFF83A2C1 : 0xFF7D9FB0);
    canvas.drawPath(midPeak, midPaint);

    // 6. Foreground Slope (Rich Slate Navy)
    final fgSlope = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.32, size.height * 0.75)
      ..lineTo(size.width * 0.70, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.80)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fgPaint = Paint()..color = const Color(0xFF6285A7);
    canvas.drawPath(fgSlope, fgPaint);

    // 7. Iconic Transit / Al-Dallel Waypoint Sign (matches the orange bus/station sign in the video)
    final signX = size.width * 0.72;
    final signY = size.height * 0.44;

    // Pole
    final polePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(signX, signY), Offset(signX, signY + 60), polePaint);

    // Sign Box (Warm amber/orange like in video)
    final signRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(signX, signY - 4), width: 38, height: 38),
      const Radius.circular(10),
    );
    final signBg = Paint()..color = const Color(0xFFD97706);
    canvas.drawRRect(signRect, signBg);

    // Sign Border
    final signBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(signRect, signBorder);

    // Sign Icon (Bus / Transit / Headquarters marker)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(signX, signY - 4), width: 18, height: 16),
        const Radius.circular(4),
      ),
      iconPaint,
    );
    // Wheels/dots
    final dotPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(Offset(signX - 4.5, signY + 1), 2.2, dotPaint);
    canvas.drawCircle(Offset(signX + 4.5, signY + 1), 2.2, dotPaint);

    // 8. Traveler / Employee with backpack (matches character in video)
    final charX = size.width * 0.46;
    final charY = size.height * 0.52;

    // Body (Teal shirt)
    final shirtPaint = Paint()..color = const Color(0xFF0F766E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(charX, charY + 12), width: 22, height: 26),
        const Radius.circular(6),
      ),
      shirtPaint,
    );

    // Head & Hair
    final headPaint = Paint()..color = const Color(0xFFFDE68A);
    canvas.drawCircle(Offset(charX, charY - 6), 9, headPaint);
    final hairPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(charX, charY - 6), radius: 9),
      math.pi,
      math.pi,
      true,
      hairPaint,
    );

    // Backpack (Warm ochre/yellow)
    final packPaint = Paint()..color = const Color(0xFFEAB308);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(charX - 11, charY + 12), width: 10, height: 20),
        const Radius.circular(4),
      ),
      packPaint,
    );

    // Raised arm waving/pointing forward
    final armPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(charX + 8, charY + 6), Offset(charX + 28, charY + 4), armPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawCircle(center, size * 0.5, cloudPaint);
    canvas.drawCircle(Offset(center.dx - size * 0.35, center.dy + size * 0.1), size * 0.35, cloudPaint);
    canvas.drawCircle(Offset(center.dx + size * 0.35, center.dy + size * 0.1), size * 0.40, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted Glass Loading Overlay matching Frame 14s in the video:
/// Translucent blur + curved dotted arc + orbiting jet/star particle + "Logging you in" typography
class _FlightLoadingOverlay extends StatelessWidget {
  final AnimationController controller;

  const _FlightLoadingOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.white.withValues(alpha: 0.82),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Orbiting Arc with Plane / Dot Particle
              SizedBox(
                width: 140,
                height: 110,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _OrbitingFlightPainter(progress: controller.value),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'جاري تسجيل الدخول...',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'يتم تجهيز بياناتك وملفك الشخصي',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitingFlightPainter extends CustomPainter {
  final double progress;

  _OrbitingFlightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Arched flight trajectory
    final start = Offset(center.dx - 45, center.dy + 35);
    final cp1 = Offset(center.dx - 30, center.dy - 35);
    final cp2 = Offset(center.dx + 25, center.dy - 40);
    final end = Offset(center.dx + 48, center.dy - 10);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    // 1. Draw Dotted Curve (like in the video)
    final dotPaint = Paint()
      ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    const dotCount = 8;
    for (int i = 0; i <= dotCount; i++) {
      final t = i / dotCount;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        final radius = 1.5 + (i * 0.3);
        canvas.drawCircle(tangent.position, radius, dotPaint);
      }
    }

    // 2. Flying Airplane / Particle along the arc
    final currentOffset = metric.length * progress;
    final tangent = metric.getTangentForOffset(currentOffset);
    if (tangent != null) {
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);

      // Jet Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, 10, glowPaint);

      // Jet Shape
      final planePaint = Paint()
        ..color = const Color(0xFF1E3A8A)
        ..style = PaintingStyle.fill;

      final planePath = Path()
        ..moveTo(9, 0)
        ..lineTo(-5, -6)
        ..lineTo(-2, 0)
        ..lineTo(-5, 6)
        ..close();
      canvas.drawPath(planePath, planePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingFlightPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
