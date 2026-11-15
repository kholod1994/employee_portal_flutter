import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/portal_provider.dart';
import '../services/api_service.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  bool _requestSent = false;
  bool _isLoading = true;
  List<_AnnualEvaluation> _evaluations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvaluations();
    });
  }

  Future<void> _loadEvaluations() async {
    final employee = context.read<PortalProvider>().employee;
    if (employee == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await ApiService.getEvaluations(employee.id);
      final list = data.map((d) {
        return _AnnualEvaluation(
          year: d['year']?.toString() ?? '',
          score: double.tryParse(d['score']?.toString() ?? '0') ?? 0.0,
          rating: d['comment']?.toString() ?? d['rating']?.toString() ?? 'تقييم معتمد',
        );
      }).toList();
      if (mounted) {
        setState(() {
          _evaluations = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestEvaluation() async {
    final employee = context.read<PortalProvider>().employee;
    if (employee == null) return;
    setState(() => _requestSent = true);
    final success = await ApiService.submitEvaluationRequest(employee.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'تم إرسال طلب التقييم السنوي بنجاح'
              : 'تم تسجيل طلب التقييم السنوي'),
        ),
      );
    }
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
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
                              Text('سجل الأداء الوظيفي',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('نتائج السنوات السابقة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (_evaluations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE6DE)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 48, color: AppTheme.muted),
                          SizedBox(height: 12),
                          Text(
                            'لا توجد تقييمات سنوية مسجلة حتى الآن',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'ستظهر نتائج تقييم الأداء هنا فور اعتمادها من الإدارة',
                            style: TextStyle(color: AppTheme.muted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._evaluations.map((evaluation) => _EvaluationCard(evaluation: evaluation)),
                  if (_requestSent)
                    Container(
                      margin: const EdgeInsets.only(top: 14, bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: AppTheme.warning),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'طلب التقييم السنوي قيد المراجعة',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
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
                Text('التقييم السنوي ${evaluation.year}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(evaluation.rating, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.star_rounded, color: AppTheme.warning, size: 19),
          const SizedBox(width: 4),
          Text(evaluation.score.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w800)),
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
