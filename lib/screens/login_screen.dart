import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/storage/safe_storage.dart';
import '../core/theme/app_theme.dart';
import '../providers/portal_provider.dart';
import '../services/app_notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
