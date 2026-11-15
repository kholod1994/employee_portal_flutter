import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';

class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key});

  void _showMemoDetails(BuildContext context, MemoRequest request) {
    final dateStr = DateFormat('yyyy/MM/dd').format(request.submittedAt);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحالة: ${request.statusLabel.isNotEmpty ? request.statusLabel : "قيد المراجعة"}  •  $dateStr',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(request.body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _composeRequest(BuildContext context) async {
    var subject = '';
    var body = '';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إرسال طلب مذكرة داخلية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                textAlign: TextAlign.right,
                onChanged: (value) => subject = value,
                decoration: const InputDecoration(labelText: 'عنوان المذكرة'),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 4,
                textAlign: TextAlign.right,
                onChanged: (value) => body = value,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل المذكرة',
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
              if (subject.trim().isEmpty || body.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة عنوان المذكرة وتفاصيلها')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (submitted == true && context.mounted) {
      final success = await context.read<PortalProvider>().submitMemoRequest(
            subject: subject.trim(),
            body: body.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم إرسال المذكرة بنجاح' : 'تعذر إرسال المذكرة',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final myRequests = provider.myMemoRequests;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('المذكرات الداخلية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المراسلات والمذكرات', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    const Text(
                      'المذكرات الداخلية الرسمية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                      ),
                      onPressed: () => _composeRequest(context),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('كتابة مذكرة جديدة'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'سجل مذكراتي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (myRequests.isEmpty)
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
                      Icon(Icons.notes_rounded, size: 48, color: AppTheme.muted),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد مذكرات داخلية مسجلة حتى الآن',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'يمكنك إرسال طلب مذكرة جديدة عبر الزر أعلاه',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...myRequests.map(
                  (request) => Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _showMemoDetails(context, request),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFECE6DE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description_rounded, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.subject,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    request.statusLabel,
                                    style: TextStyle(
                                      color: request.statusLabel == 'مرفوض'
                                          ? AppTheme.danger
                                          : request.statusLabel == 'تمت الإحالة' || request.statusLabel == 'موافق عليه'
                                              ? AppTheme.success
                                              : AppTheme.warning,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_left_rounded, color: AppTheme.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
