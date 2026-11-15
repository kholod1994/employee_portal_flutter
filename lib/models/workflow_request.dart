enum RequestStatus { pending, approved, rejected }

extension RequestStatusLabel on RequestStatus {
  String get label => switch (this) {
        RequestStatus.pending => 'قيد المراجعة',
        RequestStatus.approved => 'موافق عليه',
        RequestStatus.rejected => 'مرفوض',
      };
}

class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String managerId;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final RequestStatus status;
  final String? approvedBy;

  /// تاريخ إرسال الطلب من قاعدة البيانات (NULL إن لم يُسجَّل).
  final DateTime? submittedAt;

  /// المرفق الأصلي إن وُجد (اسم الملف وبياناته Base64).
  final String? fileName;
  final String? fileData;

  int get days => endDate.difference(startDate).inDays + 1;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.managerId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = RequestStatus.pending,
    this.approvedBy,
    this.submittedAt,
    this.fileName,
    this.fileData,
  });

  LeaveRequest copyWith({RequestStatus? status, String? approvedBy}) {
    return LeaveRequest(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      managerId: managerId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      submittedAt: submittedAt,
      fileName: fileName,
      fileData: fileData,
    );
  }
}

class PermitRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String managerId;
  final String type;
  final DateTime date;
  final String time;
  final String reason;
  final RequestStatus status;
  final String? approvedBy;
  final DateTime? submittedAt;

  const PermitRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.managerId,
    required this.type,
    required this.date,
    required this.time,
    required this.reason,
    this.status = RequestStatus.pending,
    this.approvedBy,
    this.submittedAt,
  });

  PermitRequest copyWith({RequestStatus? status, String? approvedBy}) {
    return PermitRequest(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      managerId: managerId,
      type: type,
      date: date,
      time: time,
      reason: reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      submittedAt: submittedAt,
    );
  }
}

class MemoRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String subject;
  final String body;
  final DateTime submittedAt;

  /// حالة الطلب كما يعيدها الخادم (نص جاهز للعرض)،
  /// مثل: "قيد الانتظار" أو "معتمد" أو "تمت الإحالة".
  /// فارغة عندما لا يُرجع الخادم تسمية.
  final String statusLabel;

  const MemoRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.subject,
    required this.body,
    required this.submittedAt,
    this.statusLabel = '',
  });
}

class SupportTicket {
  final String id;
  final String employeeId;
  final String subject;
  final String details;
  final DateTime submittedAt;
  final RequestStatus status;

  /// رد الدعم على التذكرة إن وُجد.
  final String? response;

  const SupportTicket({
    required this.id,
    required this.employeeId,
    required this.subject,
    required this.details,
    required this.submittedAt,
    this.status = RequestStatus.pending,
    this.response,
  });
}

class TeamEvaluation {
  final String id;
  final String employeeId;
  final String employeeName;
  final int year;
  final double score;
  final String comment;
  final DateTime submittedAt;

  const TeamEvaluation({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.score,
    required this.comment,
    required this.submittedAt,
  });

  /// يقرأ صيغة الخادم الموحدة من `/api/portal-requests?managerId=`
  /// (حيث type = 'evaluation' ويحمل الحقلان year و score).
  factory TeamEvaluation.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    final year = json['year'];
    final submitted = json['submittedAt']?.toString() ?? '';
    return TeamEvaluation(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      year: year is num ? year.toInt() : int.tryParse('$year') ?? 0,
      score: score is num ? score.toDouble() : double.tryParse('$score') ?? 0,
      // الخادم يضع نص التقييم في `subject` (وهو نفسه `title`)
      comment: (json['comment'] ?? json['title'] ?? json['subject'] ?? '')
          .toString(),
      submittedAt: DateTime.tryParse(submitted) ?? DateTime.now(),
    );
  }
}

/// طلب موحّد يمر بتدفّق الاعتماد (مستهلكات / مذكرات / ...).
///
/// الخادم يُرجع هذه الطلبات من نقطة واحدة (`/api/portal-requests`)
/// بمفاتيح: id, employeeId, employeeName, type, title, details,
/// status, statusLabel, date (نص YYYY-MM-DD).
class PortalRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String type; // 'consumable' | 'memo' | ...
  final String title;
  final String details;
  final RequestStatus status;
  final String statusLabel;
  final String date;

  /// بنود الطلب (مستهلكات): [{name, quantity, unit}]
  final List<Map<String, dynamic>> items;

  const PortalRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.title,
    required this.details,
    this.status = RequestStatus.pending,
    this.statusLabel = '',
    required this.date,
    this.items = const [],
  });

  factory PortalRequest.fromJson(Map<String, dynamic> json) {
    final date = json['date']?.toString().trim();
    final submittedAt = json['submittedAt']?.toString().trim();
    return PortalRequest(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: (json['title'] ?? json['typeName'])?.toString() ?? '',
      details: (json['details'] ?? json['reason'])?.toString() ?? '',
      status: parseRequestStatus(json['status']?.toString()),
      statusLabel: json['statusLabel']?.toString() ?? '',
      date: (date != null && date.isNotEmpty)
          ? date
          : (submittedAt ?? ''),
      items: json['items'] is List
          ? (json['items'] as List)
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'type': type,
        'title': title,
        'details': details,
        'status': status.name,
        'statusLabel': statusLabel,
        'date': date,
        'items': items,
      };
}

/// يحوّل حالة الطلب الخام القادمة من الخادم إلى `RequestStatus`.
///
/// يشمل التسميات المستخدمة فعلياً في المسير: `delivered` (تم التسليم)
/// و`referred` (تمت الإحالة) وكلاهما يُعدّ اعتماداً من وجهة نظر الموظف.
RequestStatus parseRequestStatus(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'approved':
    case 'delivered':
    case 'referred':
    case 'completed':
      return RequestStatus.approved;
    case 'rejected':
    case 'cancelled':
    case 'canceled':
      return RequestStatus.rejected;
    default:
      return RequestStatus.pending;
  }
}

class AdvanceRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final int installments;
  final double monthlyDeduction;
  final String reason;
  final RequestStatus status;
  final String statusLabel;
  final int approvalStep;
  final String? approvedBy;
  final DateTime createdAt;

  const AdvanceRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.installments,
    required this.monthlyDeduction,
    required this.reason,
    this.status = RequestStatus.pending,
    this.statusLabel = 'قيد المراجعة',
    this.approvalStep = 0,
    this.approvedBy,
    required this.createdAt,
  });

  factory AdvanceRequest.fromJson(Map<String, dynamic> json) {
    final amount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    final inst = int.tryParse(json['installments']?.toString() ?? '1') ?? 1;
    final monthly = double.tryParse(json['monthly_deduction']?.toString() ?? '') ??
        (inst > 0 ? (amount / inst) : amount);
    final statusStr = json['status']?.toString();
    return AdvanceRequest(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? json['employeeId']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? json['employeeName']?.toString() ?? '',
      amount: amount,
      installments: inst,
      monthlyDeduction: monthly,
      reason: json['reason']?.toString() ?? '',
      status: parseRequestStatus(statusStr),
      statusLabel: json['statusLabel']?.toString() ?? statusStr ?? 'قيد المراجعة',
      approvalStep: int.tryParse(json['approval_step']?.toString() ?? '0') ?? 0,
      approvedBy: json['approvedBy']?.toString() ?? json['direct_manager_notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['submittedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
