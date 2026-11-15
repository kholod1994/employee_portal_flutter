import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/employee.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  Future<void> _showEvaluationDialog(BuildContext context, Employee member) async {
    var score = 4.0;
    var comment = '';
    final draft = await showDialog<_EvaluationDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('تقييم ${member.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('التقييم السنوي ${DateTime.now().year}', style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 8),
              Text(score.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              Slider(
                value: score,
                min: 1,
                max: 5,
                divisions: 8,
                label: score.toStringAsFixed(1),
                onChanged: (value) => setDialogState(() => score = value),
              ),
              TextField(
                maxLines: 3,
                textAlign: TextAlign.right,
                onChanged: (value) => comment = value,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات التقييم',
                  hintText: 'نقاط القوة ومجالات التطوير',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (comment.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('أضف ملاحظات التقييم قبل الإرسال')),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _EvaluationDraft(score: score, comment: comment.trim()),
                );
              },
              child: const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
    if (draft == null || !context.mounted) return;
    final saved = await context.read<PortalProvider>().submitTeamEvaluation(
          employeeId: member.id,
          score: draft.score,
          comment: draft.comment,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'تم حفظ تقييم ${member.name}'
              : 'تعذر حفظ تقييم ${member.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalProvider>();
    if (!portal.isManager) {
      return const Scaffold(body: Center(child: Text('هذه الصفحة متاحة للمدير فقط')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('فريقي'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'أعضاء الفريق'),
              Tab(text: 'التقييمات المرسلة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TeamMemberList(
              members: portal.teamMembers,
              onEvaluate: (member) => _showEvaluationDialog(context, member),
            ),
            _TeamEvaluationList(evaluations: portal.teamEvaluations),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberList extends StatelessWidget {
  final List<Employee> members;
  final ValueChanged<Employee> onEvaluate;

  const _TeamMemberList({required this.members, required this.onEvaluate});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = members[index];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECE6DE)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                foregroundColor: AppTheme.primary,
                child: Text(member.name.characters.first),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(member.position, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تقييم الموظف',
                onPressed: () => onEvaluate(member),
                icon: const Icon(Icons.rate_review_outlined),
                color: AppTheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamEvaluationList extends StatelessWidget {
  final List<TeamEvaluation> evaluations;

  const _TeamEvaluationList({required this.evaluations});

  @override
  Widget build(BuildContext context) {
    if (evaluations.isEmpty) {
      return const Center(child: Text('لم يتم إرسال تقييمات بعد', style: TextStyle(color: AppTheme.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: evaluations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final evaluation = evaluations[index];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECE6DE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(evaluation.employeeName, style: const TextStyle(fontWeight: FontWeight.w800))),
                  const Icon(Icons.star_rounded, color: AppTheme.warning, size: 18),
                  Text(evaluation.score.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 5),
              Text('التقييم السنوي ${evaluation.year}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              const SizedBox(height: 8),
              Text(evaluation.comment),
            ],
          ),
        );
      },
    );
  }
}

class _EvaluationDraft {
  final double score;
  final String comment;

  const _EvaluationDraft({required this.score, required this.comment});
}
