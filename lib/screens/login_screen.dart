import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../core/storage/safe_storage.dart';
import '../core/theme/app_theme.dart';
import '../providers/portal_provider.dart';
import '../services/app_notification_service.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  final _storage = const SafeStorage();
  bool _canBiometric = false;
  bool _hasBiometricCreds = false;
  String _biometricLabel = 'البصمة أو الوجه';
  bool _isBiometricLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final canAuth = await BiometricService.canAuthenticate();
      final hasCreds = await BiometricService.hasSavedCredentials();
      final label = await BiometricService.getBiometricLabel();
      if (mounted) {
        setState(() {
          _canBiometric = canAuth;
          _hasBiometricCreds = hasCreds;
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
        _showMessage('لا توجد بيانات اعتماد محفوظة للمصادقة الحيوية');
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
        value: _identifierController.text,
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
      _showMessage(result['error'] ?? 'فشل تسجيل الدخول');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF9F3EA), Color(0xFFF4F8F9)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [AppTheme.primary, AppTheme.accent],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/logo_dallel_white.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'بوابة الموظف',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'منصة الموارد البشرية الذكية',
                      style: TextStyle(fontSize: 15, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سجّل الدخول بالبريد الإلكتروني أو الرقم الوظيفي وكلمة المرور المسجلين في النظام',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني أو الرقم الوظيفي',
                        hintText: 'أدخل البريد الإلكتروني أو الرقم الوظيفي',
                        prefixIcon: const Icon(Icons.badge_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: 'أدخل كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppTheme.primary,
                        ),
                        const Text(
                          'تذكر بياناتي',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: provider.isLoading ? null : _handleLogin,
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          provider.isLoading
                              ? 'جاري تسجيل الدخول...'
                              : 'تسجيل الدخول',
                        ),
                      ),
                    ),
                    if (_canBiometric && _hasBiometricCreds) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'أو استخدام',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.04),
                          ),
                          onPressed: (_isBiometricLoading || provider.isLoading)
                              ? null
                              : _handleBiometricLogin,
                          icon: _isBiometricLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _biometricLabel.contains('الوجه')
                                      ? Icons.face_rounded
                                      : Icons.fingerprint_rounded,
                                  color: AppTheme.primary,
                                  size: 26,
                                ),
                          label: Text(
                            'الدخول عبر $_biometricLabel',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        AppConfig.fullVersionString,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
