import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    final subject = _subjectController.text.trim();
    final details = _detailsController.text.trim();
    if (subject.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان الطلب وتفاصيله')),
      );
      return;
    }
    context.read<PortalProvider>().submitSupportTicket(
          subject: subject,
          details: details,
        );
    _subjectController.clear();
    _detailsController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الطلب بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<PortalProvider>().mySupportTickets;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('الدعم الفني'),
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFECE6DE)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنشاء طلب دعم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'الرجاء إدخال تفاصيل المشكلة أو الطلب. سيتم مراجعة الطلب من فريق الدعم خلال 24 ساعة.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _subjectController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'عنوان الطلب',
                  hintText: 'مثال: تعذر تسجيل الحضور',
                  prefixIcon: Icon(Icons.subject_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل الطلب',
                  hintText: 'اكتب تفاصيل طلبك هنا...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitRequest,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('إرسال الطلب'),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text('طلباتي السابقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  Text(tickets.length.toString(), style: const TextStyle(color: AppTheme.muted)),
                ],
              ),
              const SizedBox(height: 12),
              if (tickets.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد طلبات سابقة')))
              else
                ...tickets.map((ticket) => _SupportTicketCard(ticket: ticket)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const _SupportTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      RequestStatus.approved => AppTheme.success,
      RequestStatus.rejected => AppTheme.danger,
      RequestStatus.pending => AppTheme.warning,
    };
    final date = '${ticket.submittedAt.day.toString().padLeft(2, '0')}/${ticket.submittedAt.month.toString().padLeft(2, '0')}/${ticket.submittedAt.year}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE6DE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${ticket.id}  •  $date', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
              ],
            ),
          ),
          Text(ticket.status.label, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
