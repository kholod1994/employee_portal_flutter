import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';
import '../widgets/employee_photo.dart';
import '../widgets/portal_bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final employee = provider.employee;
    final greetingName = employee?.name.split(' ').first ?? 'الموظف';
    final payroll = provider.payrollSummary;
    final payrollAvailable = payroll != null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: 'التنبيهات',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: Badge(
              isLabelVisible: provider.notifications.isNotEmpty,
              label: Text('${provider.notifications.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            onPressed: () async {
              await provider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [AppTheme.primary, Color(0xFF1C7B8F)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مرحباً بك،',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            greetingName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  employee?.position ?? 'موظف',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    EmployeePhoto(
                      path: employee?.photoPath,
                      size: 70,
                      radius: 22,
                    ),
                  ],
                ),
              ),
              ),
              if (provider.lateDays >= 3) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تنبيه تجاوز حد التأخير (3 أيام فما فوق)',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'لديك ${provider.lateDays} أيام تأخير. وفق لائحة النظام: عند وصول الموظف إلى 3 أيام تأخير يضاف يوم غياب جزاء (المحتسب: +${provider.delayPenaltyDays} يوم غياب).',
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              const Text(
                'الخدمات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: [
                  _ServiceCard(
                    icon: Icons.person_rounded,
                    title: 'الملف الشخصي',
                    description: 'البيانات الوظيفية والشخصية',
                    route: '/profile',
                    indicator: 'محدث',
                    indicatorColor: const Color(0xFF10B981),
                  ),
                  _ServiceCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'الحضور والانصراف',
                    description: provider.delayPenaltyDays > 0
                        ? 'تأخير: ${provider.lateDays} أيام (+${provider.delayPenaltyDays} جزاء غياب)'
                        : 'سجل الوصول والغياب',
                    route: '/attendance',
                    indicator: provider.lateDays >= 3
                        ? 'تنبيه تأخير'
                        : 'هذا الشهر',
                    indicatorColor: provider.lateDays >= 3
                        ? const Color(0xFFD97706)
                        : const Color(0xFF0D4C6A),
                  ),
                  _ServiceCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'سلفني',
                    description: 'طلب سلفة مالية وتقسيط السداد',
                    route: '/advance-request',
                    indicator: 'خدمة سلفني',
                    indicatorColor: const Color(0xFF0D9488),
                  ),
                  _ServiceCard(
                    icon: Icons.payments_rounded,
                    title: 'راتبك',
                    description: payrollAvailable && payroll.isApproved
                        ? 'صافي الراتب المعتمد: ${_formatCurrency(payroll.netSalary)} د.ل'
                        : (payrollAvailable
                            ? 'بانتظار اعتماد كشف الراتب'
                            : 'ستظهر البيانات المالية بعد اعتماد الكشف'),
                    route: '/payroll',
                    indicator: payrollAvailable && payroll.isApproved
                        ? 'معتمد'
                        : (payrollAvailable ? 'قيد الاعتماد' : 'غير متوفر'),
                    indicatorColor: payroll?.isApproved == true
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                  _ServiceCard(
                    icon: Icons.beach_access_rounded,
                    title: 'الإجازات',
                    description: 'الطلبات ورصيد الإجازة',
                    route: '/leave',
                    indicator: provider.myLeaveRequests.any((r) => r.status == RequestStatus.pending)
                        ? 'قيد المراجعة'
                        : ((provider.leaveBalance['remaining'] ?? 0) > 0
                            ? '${provider.leaveBalance['remaining']} يوم متبقي'
                            : 'رصيد الإجازات'),
                    indicatorColor: provider.myLeaveRequests.any((r) => r.status == RequestStatus.pending)
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                  _ServiceCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'المستهلكات',
                    description: 'طلبات اللوازم والمعدات',
                    route: '/consumables',
                    indicator: 'طلب جديد',
                    indicatorColor: const Color(0xFF3B82F6),
                  ),
                  _ServiceCard(
                    icon: Icons.access_time_filled_rounded,
                    title: 'الأذونات',
                    description: 'رصيد الأذونات وطلبات الدخول والخروج',
                    route: '/permits',
                    indicator: 'طلب إذن',
                    indicatorColor: AppTheme.warning,
                  ),
                  _ServiceCard(
                    icon: Icons.sticky_note_2_rounded,
                    title: 'المذكرة الداخلية',
                    description: 'التعاميم والإشعارات الداخلية',
                    route: '/memo',
                    indicator: 'المذكرات',
                    indicatorColor: AppTheme.accent,
                  ),
                  _ServiceCard(
                    icon: Icons.stars_rounded,
                    title: 'تقييم الأداء',
                    description: 'التقييمات السنوية وطلب تقييم جديد',
                    route: '/evaluation',
                    indicator: 'سنوي',
                    indicatorColor: AppTheme.primary,
                  ),
                  _ServiceCard(
                    icon: Icons.support_agent_rounded,
                    title: 'الدعم',
                    description: 'شكاوى وإدارة الطلبات',
                    route: '/support',
                    indicator: '3 تذاكر',
                    indicatorColor: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
              if (provider.isManager) ...[
                const SizedBox(height: 26),
                const Text(
                  'إدارة الفريق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _ServiceCard(
                      icon: Icons.fact_check_rounded,
                      title: 'موافقات الفريق',
                      description: 'الإجازات والأذونات والمذكرات والمستهلكات',
                      route: '/team-approvals',
                      indicator: 'طلبات معلقة',
                      indicatorColor: AppTheme.warning,
                    ),
                    _ServiceCard(
                      icon: Icons.groups_rounded,
                      title: 'فريقي',
                      description: 'أعضاء الفريق والتقييم السنوي',
                      route: '/team',
                      indicator: '${provider.teamMembers.length} موظفين',
                      indicatorColor: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PortalBottomNavigation(selectedIndex: 0),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final String indicator;
  final Color indicatorColor;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.indicator,
    required this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: indicatorColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: indicatorColor),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: indicatorColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    indicator,
                    style: TextStyle(
                      color: indicatorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

String _formatCurrency(double amount) =>
    NumberFormat('#,##0', 'en').format(amount);
