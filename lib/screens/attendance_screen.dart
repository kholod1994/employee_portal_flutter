import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/portal_provider.dart';
import '../widgets/portal_bottom_navigation.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<PortalProvider>().attendance;
    final presentDays = attendance
        .where((record) => record.status == 'present')
        .length;
    final lateDays = attendance
        .where((record) => record.status == 'late')
        .length;
    final absentDays = attendance
        .where((record) => record.status == 'absent')
        .length;
    final attendanceRate = attendance.isEmpty
        ? 0
        : ((presentDays / attendance.length) * 100).round();

    // لائحة النظام المحدثة: كل 3 أيام تأخير = 1 يوم غياب جزاء
    final delayPenaltyDays = lateDays ~/ 3;
    final totalDeductionDays = absentDays + delayPenaltyDays;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الحضور والانصراف'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Attendance Header Banner
              Container(
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
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نسبة الانضباط الشهري',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$attendanceRate%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Alert Banner if lateDays >= 3 (قاعدة الـ 3 أيام المحدثة في النظام)
              if (lateDays >= 3)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              'تنبيه تجاوز حد التأخير (3 أيام)',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'تجاوز التأخير $lateDays أيام تأخير. وفقاً للائحة المعتمدة بالنظام: عند وصول الموظف إلى 3 أيام تأخير يضاف يوم غياب جزاء (تم احتساب $delayPenaltyDays يوم غياب كجزاء).',
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Stats Row 1: أيام الحضور + أيام التأخير
              Row(
                children: [
                  Expanded(
                    child: _AttendanceStat(
                      label: 'أيام الحضور',
                      value: presentDays.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttendanceStat(
                      label: 'أيام التأخير',
                      value: lateDays.toString(),
                      icon: Icons.schedule_rounded,
                      color: lateDays >= 3
                          ? const Color(0xFFD97706)
                          : AppTheme.warning,
                      extra: lateDays >= 3 ? '⚠️ تجاوز 3 أيام' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats Row 2: أيام الغياب + جزاء التأخير + إجمالي الخصم
              Row(
                children: [
                  Expanded(
                    child: _AttendanceStat(
                      label: 'أيام الغياب',
                      value: absentDays.toString(),
                      icon: Icons.cancel_outlined,
                      color: AppTheme.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttendanceStat(
                      label: 'جزاء التأخير (أيام)',
                      value: '+$delayPenaltyDays',
                      icon: Icons.gavel_rounded,
                      color: delayPenaltyDays > 0
                          ? const Color(0xFFB45309)
                          : AppTheme.muted,
                      extra: 'كل 3 أيام = 1 غياب',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttendanceStat(
                      label: 'إجمالي أيام الخصم',
                      value: totalDeductionDays.toString(),
                      icon: Icons.trending_down_rounded,
                      color: totalDeductionDays > 0
                          ? const Color(0xFFBE123C)
                          : AppTheme.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'سجل الحضور اليومي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (attendance.isEmpty)
                const _AttendanceEmptyState()
              else
                ...attendance.map((record) {
                  final isPresent = record.status == 'present';
                  final isLate = record.status == 'late';
                  final status = isPresent
                      ? 'حاضر'
                      : isLate
                      ? 'متأخر'
                      : 'غياب';
                  final statusColor = isPresent
                      ? AppTheme.success
                      : isLate
                      ? AppTheme.warning
                      : AppTheme.danger;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFECE6DE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isPresent
                                ? Icons.task_alt_rounded
                                : isLate
                                ? Icons.more_time_rounded
                                : Icons.close_rounded,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.date,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPresent || isLate
                                    ? 'دخول ${record.checkIn ?? '—'} • خروج ${record.checkOut ?? '—'}'
                                    : 'غياب كامل',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PortalBottomNavigation(selectedIndex: 1),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? extra;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 3),
            Text(
              extra!,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceEmptyState extends StatelessWidget {
  const _AttendanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, color: AppTheme.muted, size: 30),
          SizedBox(height: 8),
          Text(
            'لا توجد سجلات حضور لهذا الشهر',
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
