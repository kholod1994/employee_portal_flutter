import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  bool _requestSent = false;

  static const _evaluations = [
    _AnnualEvaluation(year: '2025', score: 4.7, rating: 'متميز'),
    _AnnualEvaluation(year: '2024', score: 4.4, rating: 'يفوق التوقعات'),
    _AnnualEvaluation(year: '2023', score: 4.2, rating: 'يفوق التوقعات'),
  ];

  void _requestEvaluation() {
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب التقييم السنوي')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('تقييم الأداء'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [AppTheme.primary, Color(0xFF1C7B8F)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التقييمات السنوية', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 4),
                        Text('سجل الأداء الوظيفي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text('نتائج السنوات السابقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Text('بيانات تجريبية', style: TextStyle(color: AppTheme.muted.withValues(alpha: 0.85), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            ..._evaluations.map((evaluation) => _EvaluationCard(evaluation: evaluation)),
            if (_requestSent)
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: AppTheme.warning),
                    SizedBox(width: 9),
                    Expanded(child: Text('طلب التقييم السنوي قيد المراجعة', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _requestSent ? null : _requestEvaluation,
                icon: Icon(_requestSent ? Icons.check_rounded : Icons.add_task_rounded),
                label: Text(_requestSent ? 'تم إرسال الطلب' : 'طلب تقييم سنوي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final _AnnualEvaluation evaluation;

  const _EvaluationCard({required this.evaluation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التقييم السنوي ${evaluation.year}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(evaluation.rating, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.star_rounded, color: AppTheme.warning, size: 19),
          const SizedBox(width: 4),
          Text(evaluation.score.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AnnualEvaluation {
  final String year;
  final double score;
  final String rating;

  const _AnnualEvaluation({
    required this.year,
    required this.score,
    required this.rating,
  });
}
