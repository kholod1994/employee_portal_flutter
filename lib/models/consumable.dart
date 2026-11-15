/// نماذج طلبات المستهلكات.
///
/// ملاحظة: الشاشة حالياً تعمل ببيانات وهمية محلية، لكن هذه النماذج هي
/// العقد الذي تبني عليه الشاشة، لذا بُنيت لتتوافق مع كل ما تستخدمه
/// `consumables_screen.dart` (بيانات submittedAt/decidedAt بصيغة BigInt
/// لأن الخادم يُرجعها كـ BIGINT ميلي‑ثانية).

enum ConsumableStatus { pending, approved, rejected }

/// مرحلة التدفّق التي وصل إليها الطلب.
enum ApprovalStage { directManager, upperManager, completed }

class ConsumableItem {
  final String name;
  final int quantity;

  const ConsumableItem({required this.name, required this.quantity});

  factory ConsumableItem.fromJson(Map<String, dynamic> json) {
    return ConsumableItem(
      name: json['name']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};
}

class ConsumableRequest {
  final String id;
  final String employeeName;
  final String employeeNumber;
  final List<ConsumableItem> items;
  final String notes;
  final BigInt submittedAt;
  final BigInt? decidedAt;
  final ConsumableStatus status;
  final ApprovalStage stage;
  final String? currentApproverName;

  const ConsumableRequest({
    required this.id,
    required this.employeeName,
    required this.employeeNumber,
    required this.items,
    this.notes = '',
    required this.submittedAt,
    this.decidedAt,
    this.status = ConsumableStatus.pending,
    this.stage = ApprovalStage.directManager,
    this.currentApproverName,
  });

  factory ConsumableRequest.fromJson(Map<String, dynamic> json) {
    return ConsumableRequest(
      id: json['id']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      employeeNumber: json['employeeNumber']?.toString() ?? '',
      items: json['items'] != null
          ? (json['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ConsumableItem.fromJson)
              .toList(growable: false)
          : const [],
      notes: json['notes']?.toString() ?? '',
      submittedAt: _asBigInt(json['submittedAt']) ?? BigInt.zero,
      decidedAt: _asBigInt(json['decidedAt']),
      status: _statusFrom(json['status']),
      stage: _stageFrom(json['stage']),
      currentApproverName: json['currentApproverName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'employeeNumber': employeeNumber,
        'items': items.map((e) => e.toJson()).toList(),
        'notes': notes,
        'submittedAt': submittedAt.toString(),
        'decidedAt': decidedAt?.toString(),
        'status': status.name,
        'stage': stage.name,
        'currentApproverName': currentApproverName,
      };
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString().trim()) ?? 0;
}

BigInt? _asBigInt(dynamic value) {
  if (value == null) return null;
  if (value is BigInt) return value;
  if (value is int) return BigInt.from(value);
  if (value is num) return BigInt.from(value.round());
  final text = value.toString().trim();
  return BigInt.tryParse(text) ??
      (double.tryParse(text) != null
          ? BigInt.from(double.parse(text).round())
          : null);
}

ConsumableStatus _statusFrom(dynamic value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'approved':
    case 'موافق عليه':
      return ConsumableStatus.approved;
    case 'rejected':
    case 'مرفوض':
      return ConsumableStatus.rejected;
    default:
      return ConsumableStatus.pending;
  }
}

ApprovalStage _stageFrom(dynamic value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'uppermanager':
    case 'upper_manager':
      return ApprovalStage.upperManager;
    case 'completed':
      return ApprovalStage.completed;
    default:
      return ApprovalStage.directManager;
  }
}
