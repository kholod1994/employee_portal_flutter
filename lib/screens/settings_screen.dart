import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../providers/portal_provider.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../widgets/employee_photo.dart';
import '../widgets/nav_bar_style_selector.dart';
import '../widgets/portal_bottom_navigation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final employee = provider.employee;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Employee Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [AppTheme.primary, Color(0xFF15617D)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        EmployeePhoto(path: employee?.photoPath, size: 64),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee?.name ?? 'اسم الموظف',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                employee?.position ?? 'المسمى الوظيفي',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'الرقم الوظيفي: ${employee?.employeeNumber ?? "-"}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_box_outlined,
                                  color: Color(0xFF2DD4BF),
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'عرض تفاصيل الملف الشخصي',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Header: إعدادات الأمان
              Text(
                'الحساب والأمان',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),

              // 2. Biometric Authentication Card
              const _BiometricSettingsCard(),

              const SizedBox(height: 12),

              // 3. Change Password Card
              const _SettingsChangePasswordCard(),

              const SizedBox(height: 22),

              // Section Header: تخصيص المظهر
              Text(
                'تخصيص المظهر والتنقل',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),

              // 3. Navigation Bar Style Selector Card
              const NavBarStyleSelectorCard(),

              const SizedBox(height: 22),

              // Section Header: عام
              Text(
                'عام والنظام',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),

              // 4. App Info & Logout Cards
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'عن التطبيق',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'شركة الدليل الرقمي لتقنية المعلومات والنظم الجغرافية - ${AppConfig.fullVersionString}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppConfig.displayVersion,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      onTap: () => _confirmLogout(context, provider),
                      leading: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.danger,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'تسجيل الخروج',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.danger,
                        ),
                      ),
                      subtitle: Text(
                        'إنهاء الجلسة الحالية من هذا الجهاز',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PortalBottomNavigation(selectedIndex: 3),
    );
  }

  void _confirmLogout(BuildContext context, PortalProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppTheme.danger),
            const SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من البوابة؟',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: AppTheme.muted, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
              }
            },
            child: Text(
              'خروج',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsChangePasswordCard extends StatelessWidget {
  const _SettingsChangePasswordCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFF0D4C6A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: Color(0xFF0D4C6A),
            size: 22,
          ),
        ),
        title: Text(
          'تغيير كلمة المرور',
          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'تحديث كلمة مرور الحساب لحماية بياناتك',
          style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.muted),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppTheme.muted,
        ),
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => const _SettingsChangePasswordDialog(),
        ),
      ),
    );
  }
}

class _SettingsChangePasswordDialog extends StatefulWidget {
  const _SettingsChangePasswordDialog();

  @override
  State<_SettingsChangePasswordDialog> createState() =>
      _SettingsChangePasswordDialogState();
}

class _SettingsChangePasswordDialogState
    extends State<_SettingsChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.changePassword(
      currentPassword: _oldController.text.trim(),
      newPassword: _newController.text.trim(),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res['message'] ?? 'تم تغيير كلمة المرور بنجاح',
                  style: GoogleFonts.cairo(),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'فشل تغيير كلمة المرور';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تغيير كلمة المرور',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.cairo(
                              color: AppTheme.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _oldController,
                  obscureText: _obscureOld,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    labelStyle: GoogleFonts.cairo(fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOld
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال كلمة المرور الحالية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    labelStyle: GoogleFonts.cairo(fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال كلمة المرور الجديدة';
                    }
                    if (v.trim().length < 6) {
                      return 'كلمة المرور يجب أن لا تقل عن 6 خانات';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    labelStyle: GoogleFonts.cairo(fontSize: 13),
                    prefixIcon: const Icon(Icons.check_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v != _newController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'حفظ التغييرات',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricSettingsCard extends StatefulWidget {
  const _BiometricSettingsCard();

  @override
  State<_BiometricSettingsCard> createState() => _BiometricSettingsCardState();
}

class _BiometricSettingsCardState extends State<_BiometricSettingsCard> {
  bool _canAuthenticate = false;
  bool _isEnabled = false;
  String _biometricLabel = 'البصمة أو الوجه';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (kIsWeb) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final canAuth = await BiometricService.canAuthenticate();
      final enabled = await BiometricService.isBiometricEnabled();
      final label = await BiometricService.getBiometricLabel();
      if (mounted) {
        setState(() {
          _canAuthenticate = canAuth;
          _isEnabled = enabled;
          _biometricLabel = label;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // 1. Authenticate with biometrics first
      final authenticated = await BiometricService.authenticate(
        localizedReason: 'يرجى تأكيد الهوية لتفعيل تسجيل الدخول بـ $_biometricLabel',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء المصادقة الحيوية أو لم يتم التعرف على البصمة'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 2. Check if we already have saved credentials
      final hasCreds = await BiometricService.hasSavedCredentials();
      if (!hasCreds) {
        if (!mounted) return;
        final provider = context.read<PortalProvider>();
        final employee = provider.employee;
        final identifier = employee?.employeeNumber ?? employee?.email ?? '';

        final password = await showDialog<String>(
          context: context,
          builder: (ctx) => _BiometricPasswordDialog(biometricLabel: _biometricLabel),
        );
        if (password == null || password.isEmpty) return;
        if (!mounted) return;

        if (identifier.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تعذر تحديد معرف الموظف لحفظ بيانات البصمة'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() => _isLoading = true);
        final verify = await ApiService.login(identifier, password);
        setState(() => _isLoading = false);

        if (verify['success'] != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('كلمة المرور غير صحيحة، لم يتم تفعيل البصمة'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        await BiometricService.saveCredentials(identifier, password);
      } else {
        await BiometricService.setBiometricEnabled(true);
      }

      if (mounted) {
        setState(() => _isEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تفعيل تسجيل الدخول بـ $_biometricLabel بنجاح'),
            backgroundColor: const Color(0xFF0D4C6A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await BiometricService.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _isEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إيقاف تسجيل الدخول بـ $_biometricLabel'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.blueGrey,
              size: 22,
            ),
          ),
          title: Text(
            'تسجيل الدخول بالبصمة / Face ID',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'المصادقة الحيوية متوفرة في تطبيق الهاتف المحمول (Android)',
            style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.muted),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'تطبيق الهاتف',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    if (!_canAuthenticate && !_isLoading) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.grey,
              size: 22,
            ),
          ),
          title: Text(
            'تسجيل الدخول بالبصمة أو الوجه',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'الجهاز الحالي لا يحتوي على مستشعر حيوي مفعل أو بصمة مسجلة',
            style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.muted),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isEnabled
              ? const Color(0xFF0D4C6A).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: _isEnabled
                ? const Color(0xFF0D4C6A).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: (_isEnabled ? const Color(0xFF0D4C6A) : Colors.grey.shade400)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _biometricLabel.contains('الوجه')
                ? Icons.face_rounded
                : Icons.fingerprint_rounded,
            color: _isEnabled ? const Color(0xFF0D4C6A) : Colors.grey.shade600,
            size: 24,
          ),
        ),
        title: Text(
          'تسجيل الدخول بـ $_biometricLabel',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          _isEnabled
              ? 'مفعّل: يمكنك الدخول السريع عبر المصادقة الحيوية'
              : 'معطّل: اضغط للتفعيل وتسجيل الدخول بلمسة واحدة',
          style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.muted),
        ),
        value: _isEnabled,
        activeTrackColor: const Color(0xFF0D4C6A),
        onChanged: _isLoading ? null : (v) => _toggleBiometric(v),
      ),
    );
  }
}

class _BiometricPasswordDialog extends StatefulWidget {
  final String biometricLabel;
  const _BiometricPasswordDialog({required this.biometricLabel});

  @override
  State<_BiometricPasswordDialog> createState() =>
      _BiometricPasswordDialogState();
}

class _BiometricPasswordDialogState extends State<_BiometricPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D4C6A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: Color(0xFF0D4C6A), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تأكيد كلمة المرور',
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لتفعيل تسجيل الدخول بـ ${widget.biometricLabel}، يرجى إدخال كلمة المرور الحالية لحفظها بأمان داخل الجهاز.',
            style: GoogleFonts.cairo(
                fontSize: 13, color: AppTheme.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              hintText: 'أدخل كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء',
              style: GoogleFonts.cairo(
                  color: AppTheme.muted, fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D4C6A),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final pass = _controller.text.trim();
            if (pass.isNotEmpty) {
              Navigator.pop(context, pass);
            }
          },
          child: Text('تأكيد وحفظ',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

