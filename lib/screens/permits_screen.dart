import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';

class PermitsScreen extends StatefulWidget {
  const PermitsScreen({super.key});

  @override
  State<PermitsScreen> createState() => _PermitsScreenState();
}

class _PermitsScreenState extends State<PermitsScreen> {
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 30);
  String _selectedType = 'دخول متأخر';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  int _usedCount(List<PermitRequest> requests, String type, DateTime month) {
    return requests.where((r) {
      if (r.status == RequestStatus.rejected) return false;
      final rDate = r.date;
      if (rDate.year != month.year || rDate.month != month.month) return false;
      if (type == 'دخول متأخر') {
        return r.type == 'دخول متأخر' || r.type == 'late-entry';
      } else if (type == 'خروج مبكر') {
        return r.type == 'خروج مبكر' || r.type == 'early-exit';
      } else if (type == 'مهام العمل') {
        return r.type == 'مهام العمل' || r.type == 'work-duty' || r.type == 'duty';
      }
      return false;
    }).length;
  }

  Future<void> _submitRequest() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة سبب طلب الإذن')),
      );
      return;
    }

    final requests = context.read<PortalProvider>().myPermitRequests;
    final lateUsed = _usedCount(requests, 'دخول متأخر', _selectedDate);
    final earlyUsed = _usedCount(requests, 'خروج مبكر', _selectedDate);

    // مهام العمل غير محدودة بأيام معينة، بينما دخول متأخر وخروج مبكر 3 أيام شهرياً
    if (_selectedType == 'دخول متأخر' && lateUsed >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد استنفدت الحد المسموح به (3 أيام في الشهر) لأذونات الدخول المتأخر'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    if (_selectedType == 'خروج مبكر' && earlyUsed >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد استنفدت الحد المسموح به (3 أيام في الشهر) لأذونات الخروج المبكر'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    try {
      await context.read<PortalProvider>().submitPermitRequest(
            type: _selectedType,
            date: _selectedDate,
            time: _selectedTime.format(context),
            reason: reason,
          );
      _reasonController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب الإذن للمراجعة'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<PortalProvider>().myPermitRequests;
    final lateUsed = _usedCount(requests, 'دخول متأخر', _selectedDate);
    final earlyUsed = _usedCount(requests, 'خروج مبكر', _selectedDate);
    final lateRemaining = (3 - lateUsed).clamp(0, 3);
    final earlyRemaining = (3 - earlyUsed).clamp(0, 3);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الأذونات ومهام العمل'),
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
              // كرت رصيد الأذونات الشهري
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                        const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'رصيد الأذونات الشهرية',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'شهر ${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceItem(
                            title: 'دخول متأخر',
                            value: '$lateRemaining من 3',
                            subtitle: 'أيام متبقية',
                            color: lateRemaining > 0 ? Colors.white : Colors.amberAccent,
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        Expanded(
                          child: _BalanceItem(
                            title: 'خروج مبكر',
                            value: '$earlyRemaining من 3',
                            subtitle: 'أيام متبقية',
                            color: earlyRemaining > 0 ? Colors.white : Colors.amberAccent,
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        const Expanded(
                          child: _BalanceItem(
                            title: 'مهام العمل',
                            value: 'غير محدود',
                            subtitle: 'بدون سقف شهري',
                            color: Color(0xFF7DFFBE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('طلب إذن جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFECE6DE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'دخول متأخر',
                          label: Text('دخول متأخر', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.login_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'خروج مبكر',
                          label: Text('خروج مبكر', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.logout_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'مهام العمل',
                          label: Text('مهام العمل', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.business_center_rounded, size: 16),
                        ),
                      ],
                      selected: {_selectedType},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) => setState(() => _selectedType = selection.first),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedType == 'مهام العمل'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedType == 'مهام العمل'
                            ? 'إذن مهام العمل غير محدود بأيام معينة ولا يخضع لسقف 3 أيام.'
                            : _selectedType == 'دخول متأخر'
                                ? 'رصيد الدخول المتأخر: متبقي $lateRemaining من 3 أيام هذا الشهر.'
                                : 'رصيد الخروج المبكر: متبقي $earlyRemaining من 3 أيام هذا الشهر.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _selectedType == 'مهام العمل'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: Text(_formatDate(_selectedDate)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'سبب الإذن / تفاصيل المهمة',
                        hintText: 'اكتب سبب الطلب أو تفاصيل مهمة العمل',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitRequest,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('إرسال الطلب'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('طلباتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (requests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECE6DE)),
                  ),
                  child: const Text('لا توجد طلبات أذونات حتى الآن', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
                )
              else
                ...requests.map((request) => _PermitRequestTile(request: request)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _BalanceItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _PermitRequestTile extends StatelessWidget {
  final PermitRequest request;

  const _PermitRequestTile({required this.request});

  String get _typeDisplay {
    if (request.type == 'late-entry' || request.type == 'دخول متأخر') return 'دخول متأخر';
    if (request.type == 'early-exit' || request.type == 'خروج مبكر') return 'خروج مبكر';
    if (request.type == 'work-duty' || request.type == 'duty' || request.type == 'مهام العمل') return 'مهام العمل';
    return request.type;
  }

  IconData get _typeIcon {
    if (request.type == 'late-entry' || request.type == 'دخول متأخر') return Icons.login_rounded;
    if (request.type == 'early-exit' || request.type == 'خروج مبكر') return Icons.logout_rounded;
    return Icons.business_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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
              Icon(_typeIcon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(_typeDisplay, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text(request.status.label, style: TextStyle(color: _statusColor(request.status), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${_formatDate(request.date)}  •  ${request.time}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(request.reason, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

Color _statusColor(RequestStatus status) => switch (status) {
      RequestStatus.pending => AppTheme.warning,
      RequestStatus.approved => AppTheme.success,
      RequestStatus.rejected => AppTheme.danger,
    };

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
