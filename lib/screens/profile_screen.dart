import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/employee.dart';
import '../providers/portal_provider.dart';
import '../widgets/employee_photo.dart';
import '../widgets/file_attachment_preview.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<PortalProvider>().employee;
    final leaveBalance = context.watch<PortalProvider>().leaveBalance;
    final familyMembers = employee?.familyMembers ?? [];
    final education = employee?.education ?? [];
    final training = employee?.training ?? [];
    final warnings = employee?.warnings ?? [];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            children: [
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
                    EmployeePhoto(path: employee?.photoPath),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.name ?? 'اسم الموظف',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            employee?.position ?? 'المسمى الوظيفي',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'المعلومات الشخصية',
                icon: Icons.account_circle_outlined,
                items: [
                  _InfoRow(
                    label: 'الاسم',
                    value: employee?.name ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'رقم الموظف',
                    value: employee?.employeeNumber ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'البريد الإلكتروني',
                    value: employee?.email ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'رقم الهاتف',
                    value: employee?.phone ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'تاريخ الميلاد',
                    value: _formatDate(employee?.birthDate),
                  ),
                  _InfoRow(
                    label: 'الرقم الوطني',
                    value: employee?.nationalId ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'الحالة الاجتماعية',
                    value: employee?.maritalStatus ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'الجنس',
                    value: employee?.gender ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'فصيلة الدم',
                    value: employee?.bloodType ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'العنوان',
                    value: employee?.address ?? 'غير متوفر',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _InfoCard(
                title: 'المعلومات الوظيفية',
                icon: Icons.work_outline_rounded,
                items: [
                  _InfoRow(
                    label: 'الإدارة',
                    value: employee?.department ?? 'غير متوفر',
                  ),
                  if (employee?.branchName != null && employee!.branchName!.isNotEmpty)
                    _InfoRow(
                      label: 'الفرع',
                      value: employee!.branchName!,
                    ),
                  if (employee?.sectionName != null && employee!.sectionName!.isNotEmpty)
                    _InfoRow(
                      label: 'القسم',
                      value: employee!.sectionName!,
                    ),
                  if (employee?.unitName != null && employee!.unitName!.isNotEmpty)
                    _InfoRow(
                      label: 'الوحدة',
                      value: employee!.unitName!,
                    ),
                  if (employee?.directManagerName != null && employee!.directManagerName!.isNotEmpty)
                    _InfoRow(
                      label: 'المدير المباشر',
                      value: employee!.directManagerName!,
                    ),
                  if (employee?.upperManagerName != null && employee!.upperManagerName!.isNotEmpty)
                    _InfoRow(
                      label: 'المدير الأعلى',
                      value: employee!.upperManagerName!,
                    ),
                  _InfoRow(
                    label: 'الوظيفة',
                    value: employee?.position ?? 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'الحالة الوظيفية',
                    value: employee?.employmentStatus.isNotEmpty == true
                        ? employee!.employmentStatus
                        : 'غير متوفر',
                  ),
                  _InfoRow(
                    label: 'تاريخ الانضمام',
                    value: _formatDate(employee?.joinDate),
                  ),
                  _InfoRow(
                    label: 'رصيد الإجازات',
                    value: '${leaveBalance['remaining'] ?? 0} يوم',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECE6DE)),
                ),
                child: CheckboxListTile(
                  value: employee?.isActive ?? false,
                  onChanged: null,
                  title: Text(
                    employee?.isActive == true ? 'حساب الموظف نشط' : 'حساب الموظف غير نشط',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('تُدار هذه الحالة من الموارد البشرية'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              if (familyMembers.isNotEmpty) ...[
                const SizedBox(height: 18),
                _InfoCard(
                  title: 'أفراد العائلة',
                  icon: Icons.family_restroom_outlined,
                  items: familyMembers
                      .map(
                        (member) => _InfoRow(
                          label: member.relation ?? 'فرد',
                          value: member.name ?? 'غير متوفر',
                        ),
                      )
                      .toList(),
                ),
              ],
              if (education.isNotEmpty) ...[
                const SizedBox(height: 18),
                _EducationCard(education: education, formatDate: _formatDate),
              ],
              if (training.isNotEmpty) ...[
                const SizedBox(height: 18),
                _TrainingCard(training: training, formatDate: _formatDate),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 18),
                _WarningCard(warnings: warnings, formatDate: _formatDate),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'غير متوفر';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date;
    }
  }
}

class _WarningCard extends StatelessWidget {
  final List<EmployeeWarning> warnings;
  final String Function(String?) formatDate;

  const _WarningCard({required this.warnings, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.danger.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
              const SizedBox(width: 8),
              Text(
                'الإنذارات (${warnings.length})',
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warning.investigationNumber?.isNotEmpty == true)
                    Text('محضر التحقيق: ${warning.investigationNumber}'),
                  if (warning.date?.isNotEmpty == true)
                    Text('التاريخ: ${formatDate(warning.date)}'),
                  if (warning.description?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(warning.description ?? ''),
                    ),
                  if (warning.fileName != null || warning.fileData != null) ...[
                    const SizedBox(height: 8),
                    FileAttachmentPreview(
                      fileName: warning.fileName,
                      fileData: warning.fileData,
                      imageSize: 100,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> items;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final List<Education> education;
  final String Function(String?) formatDate;

  const _EducationCard({required this.education, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: AppTheme.primary, size: 21),
              const SizedBox(width: 8),
              const Text(
                'التعليم',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...education.map(
            (edu) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu.degree ?? 'الدرجة',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('التخصص: ${edu.specialization ?? 'غير متوفر'}'),
                  if (edu.university?.isNotEmpty == true)
                    Text('المؤسسة: ${edu.university}'),
                  if (edu.year?.isNotEmpty == true) Text('السنة: ${edu.year}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final List<Training> training;
  final String Function(String?) formatDate;

  const _TrainingCard({required this.training, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cast_for_education_outlined,
                color: AppTheme.primary,
                size: 21,
              ),
              const SizedBox(width: 8),
              const Text(
                'الدورات التدريبية',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...training.map(
            (train) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    train.name ?? 'اسم الدورة',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (train.institution?.isNotEmpty == true)
                    Text('المؤسسة: ${train.institution}'),
                  if (train.grade?.isNotEmpty == true)
                    Text('الدرجة: ${train.grade}'),
                  if (train.startDate != null || train.endDate != null)
                    Text(
                      'الفترة: ${formatDate(train.startDate)} - ${formatDate(train.endDate)}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

