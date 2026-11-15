import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/portal_provider.dart';

class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key});

  static const _memos = [
    _InternalMemo(
      title: 'تحديث ساعات العمل الرسمية',
      date: '01 أكتوبر 2026',
      category: 'تنظيم إداري',
      body:
          'نود التذكير بأوقات الدوام الرسمي وآلية تسجيل الحضور والانصراف عبر بوابة الموظف.',
      isNew: true,
    ),
    _InternalMemo(
      title: 'إرشادات السلامة في مقر العمل',
      date: '24 سبتمبر 2026',
      category: 'تعميم',
      body:
          'يرجى الاطلاع على إرشادات السلامة المحدثة والالتزام بالتعليمات في جميع مرافق العمل.',
    ),
    _InternalMemo(
      title: 'مواعيد تحديث البيانات الوظيفية',
      date: '18 سبتمبر 2026',
      category: 'الموارد البشرية',
      body:
          'يمكن للموظفين مراجعة بياناتهم الوظيفية وتحديث معلومات التواصل من صفحة الملف الشخصي.',
    ),
  ];

  void _showMemo(BuildContext context, _InternalMemo memo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(memo.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${memo.category}  •  ${memo.date}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(memo.body),
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
        title: const Text('إرسال طلب للمذكرة'),
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
                  labelText: 'وصف المذكرة',
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
                  const SnackBar(content: Text('أكمل موضوع الطلب وتفاصيله')),
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم إرسال طلب المذكرة' : 'تعذر إرسال طلب المذكرة',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<PortalProvider>().myMemoRequests;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('المذكرة الداخلية'),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _composeRequest(context),
                  icon: const Icon(Icons.add_comment_rounded),
                  label: const Text('إرسال طلب للمذكرة الداخلية'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'طلباتي المرسلة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (requests.isEmpty)
                const Text(
                  'لا توجد طلبات مرسلة',
                  style: TextStyle(color: AppTheme.muted),
                )
              else
                ...requests.map(
                  (request) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFECE6DE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المرسل: ${request.employeeName}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          request.subject,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          request.body,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.statusLabel,
                          style: TextStyle(
                            color: request.statusLabel == 'مرفوض'
                                ? AppTheme.danger
                                : request.statusLabel == 'تمت الإحالة'
                                ? AppTheme.success
                                : AppTheme.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              const Text(
                'التعاميم الداخلية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ..._memos.map(
                (memo) => _InternalMemoCard(
                  memo: memo,
                  onTap: () => _showMemo(context, memo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternalMemoCard extends StatelessWidget {
  final _InternalMemo memo;
  final VoidCallback onTap;

  const _InternalMemoCard({required this.memo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.sticky_note_2_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            memo.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (memo.isNew)
                          const Text(
                            'جديد',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      memo.category,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      memo.date,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_left_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternalMemo {
  final String title;
  final String date;
  final String category;
  final String body;
  final bool isNew;

  const _InternalMemo({
    required this.title,
    required this.date,
    required this.category,
    required this.body,
    this.isNew = false,
  });
}
