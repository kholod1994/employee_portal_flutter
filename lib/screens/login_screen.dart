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
    with TickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isIdentifierFocused = false;
  bool _isPasswordFocused = false;

  bool _rememberMe = true;
  bool _obscurePassword = true;
  final _storage = const SafeStorage();

  bool _canBiometric = false;
  String _biometricLabel = 'البصمة أو الوجه';
  bool _isBiometricLoading = false;

  late final AnimationController _flightAnimController;
  late final AnimationController _heroMotionController;
  late final AnimationController _badgeBobController;

  @override
  void initState() {
    super.initState();

    // 1. Loading flight animation controller
    _flightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // 2. Continuous cinematic Ken-Burns motion for the real photo header
    _heroMotionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    // 3. Subtle floating bobbing animation for the glassmorphism badges
    _badgeBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // Track focus for email & password fields
    _identifierFocusNode.addListener(() {
      setState(() {
        _isIdentifierFocused = _identifierFocusNode.hasFocus;
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });

    _loadSavedCredentials();
    _checkBiometric();
  }

  @override
  void dispose() {
    _flightAnimController.dispose();
    _heroMotionController.dispose();
    _badgeBobController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
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
      _showMessage('يرجى إدخال الرقم الوظيفي أو اسم المستخدم وكلمة المرور');
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
    // Real photo header occupies approximately 40-42% of the screen height
    final topBannerHeight = math.min(size.height * 0.42, 340.0);
    final isLoading = provider.isLoading || _isBiometricLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Real Photo Animated Header with Ken Burns & Glassmorphism Badges
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBannerHeight + 40,
            child: _RealOfficeAnimatedHeader(
              motionController: _heroMotionController,
              bobController: _badgeBobController,
            ),
          ),

          // 2. Main Scrollable Content Overlapping the Photo
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: topBannerHeight),

                  // 3. Rounded White Card Sheet (matches user's screenshot)
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
                          color: Color(0x220F172A),
                          blurRadius: 30,
                          offset: Offset(0, -10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title: أهلاً بعودتك
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'أهلاً بعودتك',
                                style: GoogleFonts.cairo(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'سجّل دخولك إلى بوابة الموظفين — شركة الدليل الرقمي\nلمتابعة حضورك ومهامك وطلباتك',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Input 1: Employee ID / Username (Full width, height: 56px)
                        _buildGenerousInputField(
                          controller: _identifierController,
                          focusNode: _identifierFocusNode,
                          isFocused: _isIdentifierFocused,
                          hint: 'الرقم الوظيفي أو اسم المستخدم',
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.text,
                        ),

                        const SizedBox(height: 14),

                        // Input 2: Password (Full width, height: 56px with eye toggle)
                        _buildGenerousInputField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          isFocused: _isPasswordFocused,
                          hint: 'كلمة المرور',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),

                        const SizedBox(height: 14),

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
                                mainAxisSize: MainAxisSize.min,
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
                                      activeColor: const Color(0xFF155488),
                                      side: const BorderSide(
                                        color: Color(0xFF94A3B8),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تذكّرني',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF155488),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Primary Action Button: تسجيل الدخول (Solid Deep Navy / Ocean Blue, Height: 54px)
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF155488), Color(0xFF0F4370)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF155488).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isLoading ? null : _handleLogin,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.login_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'تسجيل الدخول',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Biometric Quick Login Button (if available)
                        if (_canBiometric) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 52,
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
                                      color: const Color(0xFF155488),
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

                        const SizedBox(height: 26),

                        // Bottom Helper / Contact HR (matches user's screenshot footer)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'ليس لديك حساب؟ ',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showMessage(
                                    'يرجى مراجعة إدارة الموارد البشرية لإنشاء وتفعيل حسابك في المنظومة',
                                  );
                                },
                                child: Text(
                                  'تواصل مع قسم الموارد البشرية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF155488),
                                  ),
                                ),
                              ),
                              Text(
                                ' لتفعيل حسابك',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // App Version Tag
                        Center(
                          child: Text(
                            AppConfig.displayVersion,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                            ),
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

  /// Generous Input Field matching user's uploaded screenshot:
  /// - Full width (double.infinity).
  /// - Height: 56px (generous vertical height).
  /// - Unfocused: Soft light grey container (#F3F5F9), no border.
  /// - Focused: Pure white (#FFFFFF), crisp dark border (#0F172A, 1.6px) with soft elevation.
  /// - Proper RTL alignment: Right-side prefix icon, right-aligned text.
  Widget _buildGenerousInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Prefix Icon (on the right side in RTL)
          Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 23,
          ),
          const SizedBox(width: 12),

          // Text Field (Completely borderless)
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: isPassword ? obscureText : false,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintTextDirection: TextDirection.rtl,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Password Visibility Toggle (on the left side in RTL)
          if (isPassword)
            IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF64748B),
                size: 22,
              ),
              onPressed: onToggleVisibility,
              splashRadius: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Real Office Animated Header:
/// Displays the real photographic image of professional team giving high-five,
/// with continuous Ken Burns motion (smooth zoom + pan drift),
/// floating glassmorphism badges ("حضور تلقائي" & "مهامك واجتماعاتك"),
/// and the company logo badge in top-right.
class _RealOfficeAnimatedHeader extends StatelessWidget {
  final AnimationController motionController;
  final AnimationController bobController;

  const _RealOfficeAnimatedHeader({
    required this.motionController,
    required this.bobController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([motionController, bobController]),
      builder: (context, child) {
        // Continuous Ken Burns zoom from 1.0 to 1.08
        final scale = 1.0 + (motionController.value * 0.08);
        final dx = math.sin(motionController.value * math.pi) * 10.0;
        final dy = math.cos(motionController.value * math.pi) * 4.0;

        // Subtle floating bobbing for badges
        final bob1 = math.sin(bobController.value * math.pi) * 4.0;
        final bob2 = math.cos(bobController.value * math.pi) * 4.0;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The Real Photo with Continuous Ken Burns Motion
              Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    'assets/images/office_team_hero.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/login_hero.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),

              // 2. Subtle Dark Vignette & Soft Gradient for contrast
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // 3. Top-Right Company Logo Badge (matching user's screenshot)
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  width: 65,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_dallel_color.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/logo_dallel_white.png',
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),

              // 4. Floating Glassmorphism Badge 1 (Left): "مهامك واجتماعاتك في مكان واحد"
              Positioned(
                top: 175 + bob1,
                left: 14,
                child: _buildGlassBadge(
                  icon: Icons.checklist_rounded,
                  title: 'مهامك واجتماعاتك',
                  subtitle: 'في مكان واحد',
                  iconBgColor: Colors.white,
                  iconColor: const Color(0xFF0F766E),
                ),
              ),

              // 5. Floating Glassmorphism Badge 2 (Right): "حضور تلقائي بدخول مساحة العمل"
              Positioned(
                bottom: 50 + bob2,
                right: 18,
                child: _buildGlassBadge(
                  icon: Icons.check_circle_rounded,
                  title: 'حضور تلقائي',
                  subtitle: 'بدخول مساحة العمل',
                  iconBgColor: Colors.white,
                  iconColor: const Color(0xFF155488),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              // Icon with clean white circle background
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              // Text column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        color: Colors.white.withValues(alpha: 0.85),
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
      ..color = const Color(0xFF155488).withValues(alpha: 0.35)
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
        ..color = const Color(0xFF155488).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, 10, glowPaint);

      // Jet Shape
      final planePaint = Paint()
        ..color = const Color(0xFF155488)
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
