import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/payroll.dart';
import '../providers/portal_provider.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payroll = context.watch<PortalProvider>().payrollSummary;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('راتبك'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: payroll == null
            ? const _PendingPayroll()
            : _PayrollDetails(payroll: payroll),
      ),
    );
  }
}

class _PayrollDetails extends StatelessWidget {
  final PayrollSummary payroll;

  const _PayrollDetails({required this.payroll});

  @override
  Widget build(BuildContext context) {
    final approvedAt = payroll.approvedAt;
    final approvalDate = approvedAt == null
        ? null
        : '${approvedAt.day.toString().padLeft(2, '0')}/${approvedAt.month.toString().padLeft(2, '0')}/${approvedAt.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [AppTheme.primary, Color(0xFF1C7B8F)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'صافي الراتب',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          payroll.isApproved ? 'معتمد' : 'تقديري',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatCurrency(payroll.netSalary)} د.ل',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${payroll.isApproved ? 'مسير' : 'تقدير راتب'} ${payroll.payPeriod}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (payroll.isApproved && approvalDate != null) ...[
                const SizedBox(height: 3),
                Text(
                  'تاريخ الاعتماد: $approvalDate',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SummaryCard(
          title: 'الاستقطاعات',
          amount: payroll.totalDeductions,
          icon: Icons.trending_down_rounded,
          color: AppTheme.danger,
          prefix: '-',
        ),
        const SizedBox(height: 22),
        const Text(
          'تفاصيل الراتب',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _surfaceDecoration,
          child: _PayrollLine(
            label: 'الراتب الأساسي',
            amount: payroll.baseSalary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'الخصميات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _PayrollItems(
          items: payroll.deductions,
          color: AppTheme.danger,
          prefix: '-',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _surfaceDecoration,
          child: _PayrollLine(
            label: 'صافي الراتب',
            amount: payroll.netSalary,
            emphasized: true,
          ),
        ),
      ],
    );
  }
}

class _PayrollItems extends StatelessWidget {
  final List<PayrollLineItem> items;
  final Color color;
  final String prefix;

  const _PayrollItems({
    required this.items,
    required this.color,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _surfaceDecoration,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _PayrollLine(
              label: items[index].title,
              amount: items[index].amount,
              color: color,
              prefix: prefix,
            ),
            if (index < items.length - 1)
              const Divider(height: 1, color: Color(0xFFECE6DE)),
          ],
        ],
      ),
    );
  }
}

class _PayrollLine extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final String prefix;
  final bool emphasized;

  const _PayrollLine({
    required this.label,
    required this.amount,
    this.color,
    this.prefix = '',
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized ? AppTheme.ink : AppTheme.muted,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$prefix${_formatCurrency(amount)} د.ل',
            style: TextStyle(
              color: color ?? AppTheme.ink,
              fontWeight: FontWeight.w800,
              fontSize: emphasized ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String prefix;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _surfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$prefix${_formatCurrency(amount)} د.ل',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPayroll extends StatelessWidget {
  const _PendingPayroll();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _surfaceDecoration,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.warning,
                size: 36,
              ),
              SizedBox(height: 12),
              Text(
                'البيانات المالية غير متوفرة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'يرجى التواصل مع إدارة الموارد البشرية لتحديث بيانات الراتب.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _surfaceDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFECE6DE)),
);

String _formatCurrency(double amount) =>
    NumberFormat('#,##0.00', 'en').format(amount);
