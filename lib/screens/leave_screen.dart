import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';
import '../widgets/portal_bottom_navigation.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  int _calculateWorkingDays(DateTime start, DateTime end) {
    if (end.isBefore(start)) return 0;
    int count = 0;
    var cur = DateTime(start.year, start.month, start.day);
    final endClean = DateTime(end.year, end.month, end.day);
    while (!cur.isAfter(endClean)) {
      if (cur.weekday != DateTime.friday && cur.weekday != DateTime.saturday) {
        count++;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _showLeaveRequest() async {
    final provider = context.read<PortalProvider>();
    final availableTypes = provider.leaveTypes.isNotEmpty
        ? provider.leaveTypes
              .map((t) => t['name']?.toString() ?? 'إجازة سنوية')
              .toList()
        : [
            'إجازة سنوية',
            'إجازة اضطرارية',
            'إجازة مرضية',
            'إجازة أمومة / رعاية',
            'إجازة بدون مرتب',
          ];

    var type = availableTypes.first;
    var reason = '';
    var startDate = DateUtils.dateOnly(DateTime.now());
    var endDate = startDate.add(const Duration(days: 1));
    String? fileName;
    String? fileData;

    final draft = await showDialog<_LeaveDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final days = _calculateWorkingDays(startDate, endDate);
          final selectedLt = provider.leaveTypes.firstWhere(
            (t) => (t['name']?.toString() ?? '') == type,
            orElse: () => <String, dynamic>{},
          );
          final isSick = selectedLt['requiresAttachment'] == true ||
              selectedLt['requires_attachment'] == true ||
              type.contains('مرض');

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'تقديم طلب إجازة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'نوع الإجازة'),
                    items: availableTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: dialogContext,
                              initialDate: startDate,
                              firstDate: DateUtils.dateOnly(DateTime.now()),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                                if (endDate.isBefore(startDate))
                                  endDate = startDate;
                              });
                            }
                          },
                          icon: const Icon(Icons.event_rounded, size: 18),
                          label: Text(
                            'من ${_formatDate(startDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: dialogContext,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null)
                              setDialogState(() => endDate = date);
                          },
                          icon: const Icon(
                            Icons.event_available_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'إلى ${_formatDate(endDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: days > 0
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: days == 0
                          ? Border.all(color: Colors.red.shade300)
                          : null,
                    ),
                    child: Text(
                      days > 0
                          ? 'عدد الأيام المطلوبة: $days يوم (مستثنى الجمعة والسبت)'
                          : 'الفترة المحددة كلها عطلة (الجمعة والسبت)',
                      style: TextStyle(
                        color: days > 0 ? AppTheme.primary : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isSick) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                color: Colors.amber,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'المرفق المطلوب (إجباري لهذا النوع من الإجازات) *',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                                  withData: true,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  final file = result.files.first;
                                  final bytes = file.bytes;
                                  if (bytes != null) {
                                    final base64Str = base64Encode(bytes);
                                    final ext = file.extension?.toLowerCase() ?? 'pdf';
                                    final mime = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
                                    setDialogState(() {
                                      fileName = file.name;
                                      fileData = 'data:$mime;base64,$base64Str';
                                    });
                                  }
                                }
                              },
                              icon: Icon(
                                fileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                                size: 18,
                                color: fileName != null ? Colors.green : AppTheme.primary,
                              ),
                              label: Text(
                                fileName ?? 'اختيار ملف التقرير الطبي (PDF / صورة)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: fileName != null ? Colors.green.shade800 : null,
                                  fontWeight: fileName != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 3,
                    textAlign: TextAlign.right,
                    onChanged: (value) => reason = value,
                    decoration: const InputDecoration(
                      labelText: 'سبب الإجازة',
                      hintText: 'أدخل سبب الإجازة أو تفاصيلها...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (isSick && (fileName == null || fileData == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('نوع الإجازة المحدد يتطلب إرفاق تقرير أو مستند رسمي')),
                    );
                    return;
                  }
                  if (days <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الفترة المحددة كلها عطلة')),
                    );
                    return;
                  }
                  if (reason.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى كتابة سبب الإجازة')),
                    );
                    return;
                  }
                  Navigator.pop(
                    dialogContext,
                    _LeaveDraft(
                      type: type,
                      startDate: startDate,
                      endDate: endDate,
                      days: days,
                      reason: reason.trim(),
                      fileName: isSick ? fileName : null,
                      fileData: isSick ? fileData : null,
                    ),
                  );
                },
                child: const Text('إرسال الطلب'),
              ),
            ],
          );
        },
      ),
    );
    if (draft == null || !mounted) return;
    context.read<PortalProvider>().submitLeaveRequest(
      type: draft.type,
      startDate: draft.startDate,
      endDate: draft.endDate,
      reason: draft.reason,
      fileName: draft.fileName,
      fileData: draft.fileData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final leaveBalance = provider.leaveBalance;
    final annual = leaveBalance['annual'] ?? 0;
    final used = leaveBalance['used'] ?? 0;
    final remaining = leaveBalance['remaining'] ?? 0;
    final usedRatio = annual == 0 ? 0.0 : (used / annual).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الإجازات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLeaveRequest,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'طلب إجازة جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppTheme.primary, Color(0xFF145374)],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رصيد الإجازات السنوية',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$remaining يوم متبقي',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'الإجمالي: $annual',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: usedRatio,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المستهلك: $used يوم',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'المتبقي: $remaining يوم',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'طلباتي السابقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (provider.myLeaveRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECE6DE)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.beach_access_rounded,
                        color: AppTheme.muted,
                        size: 36,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لا توجد طلبات إجازة مسجلة',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                )
              else
                ...provider.myLeaveRequests.map((request) {
                  final status = request.status;
                  final statusLabel = status == RequestStatus.approved
                      ? 'موافق عليها'
                      : status == RequestStatus.rejected
                      ? 'مرفوضة'
                      : 'قيد المراجعة';
                  final statusColor = status == RequestStatus.approved
                      ? AppTheme.success
                      : status == RequestStatus.rejected
                      ? AppTheme.danger
                      : AppTheme.warning;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                            Text(
                              request.type,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'من ${_date(request.startDate)} إلى ${_date(request.endDate)} (${request.days} يوم)',
                          style: TextStyle(
                            color: AppTheme.ink.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (request.reason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'السبب: ${request.reason}',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PortalBottomNavigation(selectedIndex: 2),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class _LeaveDraft {
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String reason;
  final String? fileName;
  final String? fileData;

  const _LeaveDraft({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    this.fileName,
    this.fileData,
  });
}
