import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';
import '../widgets/portal_bottom_navigation.dart';

class AdvanceScreen extends StatefulWidget {
  const AdvanceScreen({super.key});

  @override
  State<AdvanceScreen> createState() => _AdvanceScreenState();
}

class _AdvanceScreenState extends State<AdvanceScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  int _selectedInstallments = 3;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortalProvider>().loadMyAdvanceRequests();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showNewAdvanceDialog() {
    _amountController.clear();
    _reasonController.clear();
    _selectedInstallments = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
          final monthly = _selectedInstallments > 0 ? (amount / _selectedInstallments) : 0.0;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.payments_outlined, color: AppTheme.primary, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'طلب سلفة مالية جديدة (سلفني)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'يتم إرسال الطلب لمديرك المباشر للموافقة ثم للمدير الأعلى للاعتماد النهائي.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'مبلغ السلفة المطلوب (د.ل)',
                      hintText: 'مثال: 1000',
                      prefixIcon: const Icon(Icons.money_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedInstallments,
                    decoration: InputDecoration(
                      labelText: 'عدد أشهر السداد (الأقساط)',
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('شهر واحد (دفعة واحدة)')),
                      DropdownMenuItem(value: 2, child: Text('شهران (قسطان)')),
                      DropdownMenuItem(value: 3, child: Text('3 أشهر (3 أقساط)')),
                      DropdownMenuItem(value: 4, child: Text('4 أشهر')),
                      DropdownMenuItem(value: 5, child: Text('5 أشهر')),
                      DropdownMenuItem(value: 6, child: Text('6 أشهر (نصف سنة)')),
                      DropdownMenuItem(value: 10, child: Text('10 أشهر')),
                      DropdownMenuItem(value: 12, child: Text('12 شهراً (سنة كاملة)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => _selectedInstallments = val);
                    },
                  ),
                  if (amount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الخصم الشهري المقدر من الراتب:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${monthly.toStringAsFixed(2)} د.ل / شهر',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'سبب طلب السلفة / ملاحظات',
                      hintText: 'اكتب سبباً مختصراً للطلب...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final amt = double.tryParse(_amountController.text.trim());
                              if (amt == null || amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى إدخال مبلغ سلفة صالح')),
                                );
                                return;
                              }
                              setModalState(() => _isSubmitting = true);
                              final ok = await context.read<PortalProvider>().submitAdvanceRequest(
                                    amount: amt,
                                    installments: _selectedInstallments,
                                    reason: _reasonController.text.trim(),
                                  );
                              setModalState(() => _isSubmitting = false);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'تم إرسال طلب السلفة إلى مديرك المباشر بنجاح'
                                          : 'فشل إرسال طلب السلفة، يرجى المحاولة لاحقاً',
                                    ),
                                    backgroundColor: ok ? AppTheme.success : AppTheme.danger,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.send_rounded),
                      label: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إرسال طلب السلفة',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final employee = provider.employee;
    final requests = provider.myAdvanceRequests;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('سلفني - السلف المالية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const PortalBottomNavigation(selectedIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadMyAdvanceRequests(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // البطاقة العلوية
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'خدمة سلفني الفورية',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'سلف مالية ميسرة للموظفين مع تقسيط مريح',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الراتب الأساسي', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 3),
                                Text(
                                  employee?.salary != null ? '${employee!.salary} د.ل' : 'غير متوفر',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الطلبات النشطة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 3),
                                Text(
                                  '${requests.where((r) => r.status == RequestStatus.pending).length} طلبات',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showNewAdvanceDialog,
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F766E)),
                        label: const Text(
                          'تقديم طلب سلفة جديد',
                          style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'سجل طلبات السلف',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              if (requests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECE6DE)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.muted),
                      SizedBox(height: 10),
                      Text('لم تقدم أي طلب سلفة بعد', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        'اضغط على "تقديم طلب سلفة جديد" في الأعلى للبدء.',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...requests.map((adv) => _AdvanceCard(advance: adv)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvanceCard extends StatelessWidget {
  final AdvanceRequest advance;

  const _AdvanceCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (advance.status) {
      RequestStatus.approved => AppTheme.success,
      RequestStatus.rejected => AppTheme.danger,
      RequestStatus.pending => const Color(0xFFD97706),
    };

    final statusText = switch (advance.status) {
      RequestStatus.approved => 'معتمد ومصادق عليه',
      RequestStatus.rejected => 'مرفوض',
      RequestStatus.pending => advance.approvalStep == 1
          ? 'بانتظار الاعتماد النهائي'
          : 'بانتظار موافقة المدير المباشر',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE6DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${advance.amount.toStringAsFixed(2)} د.ل',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppTheme.muted),
              const SizedBox(width: 6),
              Text(
                'التقسيط: ${advance.installments} أقساط (${advance.monthlyDeduction.toStringAsFixed(2)} د.ل / شهر)',
                style: const TextStyle(fontSize: 13, color: AppTheme.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (advance.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'السبب: ${advance.reason}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.muted),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاريخ الطلب: ${DateFormat('yyyy/MM/dd', 'en').format(advance.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              if (advance.approvalStep > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    advance.approvalStep >= 2
                        ? 'مكتمل (خطوة 2 من 2)'
                        : 'موافقة أولى (خطوة 1 من 2)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: advance.approvalStep >= 2 ? AppTheme.success : Colors.blue.shade800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
