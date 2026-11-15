import 'package:flutter_test/flutter_test.dart';
import 'package:employee_portal_flutter/models/workflow_request.dart';

void main() {
  Map<String, dynamic> requestJson({
    required String type,
    required String status,
    required String statusLabel,
  }) {
    return {
      'id': '1',
      'type': type,
      'employeeId': '1001',
      'employeeName': 'موظف',
      'managerId': '',
      'typeName': 'طلب',
      'reason': 'تفاصيل',
      'date': '2026-10-12',
      'endDate': '',
      'status': status,
      'statusLabel': statusLabel,
      'approvalStep': 0,
      'items': <Map<String, dynamic>>[],
    };
  }

  test(
    'delivered consumables keep the delivery status in the employee app',
    () {
      final request = PortalRequest.fromJson(
        requestJson(
          type: 'consumable',
          status: 'delivered',
          statusLabel: 'تم التسليم',
        ),
      );

      expect(request.status, RequestStatus.approved);
      expect(request.statusLabel, 'تم التسليم');
    },
  );

  test(
    'referred internal memos keep the referral status in the employee app',
    () {
      final request = PortalRequest.fromJson(
        requestJson(
          type: 'memo',
          status: 'referred',
          statusLabel: 'تمت الإحالة',
        ),
      );

      expect(request.status, RequestStatus.approved);
      expect(request.statusLabel, 'تمت الإحالة');
    },
  );
}
