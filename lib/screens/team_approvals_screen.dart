import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/workflow_request.dart';
import '../providers/portal_provider.dart';

class TeamApprovalsScreen extends StatelessWidget {
  const TeamApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portal = context.watch<PortalProvider>();
    if (!portal.isManager) {
      return const Scaffold(body: Center(child: Text('هذه الصفحة متاحة للمدير فقط')));
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('موافقات الفريق'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الإجازات (${portal.teamLeaveRequests.where((item) => item.status == RequestStatus.pending).length})'),
              Tab(text: 'الأذونات (${portal.teamPermitRequests.where((item) => item.status == RequestStatus.pending).length})'),
              Tab(text: 'المذكرات (${portal.teamMemoRequests.where((item) => item.status == RequestStatus.pending).length})'),
              Tab(text: 'المستهلكات (${portal.teamConsumableRequests.where((item) => item.status == RequestStatus.pending).length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaveApprovalList(requests: portal.teamLeaveRequests),
            _PermitApprovalList(requests: portal.teamPermitRequests),
            _PortalRequestList(requests: portal.teamMemoRequests),
            _PortalRequestList(requests: portal.teamConsumableRequests),
          ],
        ),
      ),
    );
  }
}

class _LeaveApprovalList extends StatelessWidget {
  final List<LeaveRequest> requests;

  const _LeaveApprovalList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const _EmptyApprovals();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _LeaveApprovalCard(request: requests[index]),
    );
  }
}

class _PermitApprovalList extends StatelessWidget {
  final List<PermitRequest> requests;

  const _PermitApprovalList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const _EmptyApprovals();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _PermitApprovalCard(request: requests[index]),
    );
  }
}

/// قائمة موحّدة تُستعمل في تبويبَي المذكرات والمستهلكات،
/// لأن كليهما يعود من `/portal-requests?managerId=` بنموذج `PortalRequest`.
class _PortalRequestList extends StatelessWidget {
  final List<PortalRequest> requests;

  const _PortalRequestList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const _EmptyApprovals();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _ApprovalCard(
          employeeName: request.employeeName,
          title: request.title,
          details: request.details,
          status: request.status,
          signature: null,
          extra: request.items.isEmpty ? null : _ItemsList(items: request.items),
          onReview: (status) =>
              context.read<PortalProvider>().reviewPortalRequest(request, status),
        );
      },
    );
  }
}

class _ItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${item['name'] ?? item['itemName'] ?? ''} × '
              '${item['quantity'] ?? ''} ${item['unit'] ?? ''}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaveApprovalCard extends StatelessWidget {
  final LeaveRequest request;

  const _LeaveApprovalCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return _ApprovalCard(
      employeeName: request.employeeName,
      title: request.type,
      details: '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}\n${request.reason}',
      status: request.status,
      signature: request.approvedBy,
      onReview: (status) => context.read<PortalProvider>().reviewLeaveRequest(
        requestId: request.id,
        status: status,
      ),
    );
  }
}

class _PermitApprovalCard extends StatelessWidget {
  final PermitRequest request;

  const _PermitApprovalCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return _ApprovalCard(
      employeeName: request.employeeName,
      title: request.type,
      details: '${_formatDate(request.date)} • ${request.time}\n${request.reason}',
      status: request.status,
      signature: request.approvedBy,
      onReview: (status) => context.read<PortalProvider>().reviewPermitRequest(
        requestId: request.id,
        status: status,
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final String employeeName;
  final String title;
  final String details;
  final RequestStatus status;
  final String? signature;

  /// محتوى إضافي بين التفاصيل وأزرار المراجعة (بنود المستهلكات مثلاً)
  final Widget? extra;
  final ValueChanged<RequestStatus> onReview;

  const _ApprovalCard({
    required this.employeeName,
    required this.title,
    required this.details,
    required this.status,
    required this.signature,
    this.extra,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      RequestStatus.pending => AppTheme.warning,
      RequestStatus.approved => AppTheme.success,
      RequestStatus.rejected => AppTheme.danger,
    };
    return Container(
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
            children: [
              Expanded(child: Text(employeeName, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text(status.label, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(details, style: const TextStyle(color: AppTheme.muted, height: 1.5)),
          if (extra != null) extra!,
          if (signature != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.draw_rounded, size: 17, color: AppTheme.success),
                const SizedBox(width: 6),
                Text('اعتماد: $signature', style: const TextStyle(color: AppTheme.success, fontSize: 12)),
              ],
            ),
          ],
          if (status == RequestStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onReview(RequestStatus.rejected),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => onReview(RequestStatus.approved),
                    icon: const Icon(Icons.draw_rounded),
                    label: const Text('موافقة وتوقيع'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyApprovals extends StatelessWidget {
  const _EmptyApprovals();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('لا توجد طلبات للفريق', style: TextStyle(color: AppTheme.muted)),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
