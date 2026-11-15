import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/network/api_client.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/payroll.dart';

class ApiService {
  static Future<Map<String, dynamic>?> getEmployeeProfile(
    String employeeId,
  ) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiClient.employeeProfile}?employeeId=$employeeId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getEmployeeNotifications(
    String employeeId,
  ) async {
    final response = await ApiClient.get(
      Uri.parse('${ApiClient.baseUrl}/notifications/$employeeId'),
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Future<void> markEmployeeNotificationRead({
    required String employeeId,
    required String notificationId,
  }) async {
    final response = await ApiClient.put(
      Uri.parse(
        '${ApiClient.baseUrl}/notifications/$employeeId/$notificationId/read',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
  }

  static Future<void> markAllEmployeeNotificationsRead(
    String employeeId,
  ) async {
    final response = await ApiClient.put(
      Uri.parse('${ApiClient.baseUrl}/notifications/$employeeId/read-all'),
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
  }

  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiClient.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final token = result['token']?.toString();
        if (token == null || token.isEmpty) {
          return {'success': false, 'error': 'لم يصدر الخادم رمز تسجيل الدخول'};
        }
        await ApiClient.saveToken(token);
        return result;
      }
      final responseBody = jsonDecode(response.body);
      if (responseBody is Map<String, dynamic>) {
        return {
          'success': false,
          'error':
              responseBody['error']?.toString() ??
              responseBody['message']?.toString() ??
              'تعذر تسجيل الدخول (${response.statusCode})',
        };
      }
      return {
        'success': false,
        'error': 'تعذر تسجيل الدخول (${response.statusCode})',
      };
    } catch (e) {
      debugPrint('Login exception: $e');
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('Failed host lookup') ||
          errStr.contains('Connection refused') ||
          errStr.contains('TimeoutException') ||
          errStr.contains('NetworkException')) {
        return {
          'success': false,
          'error':
              'تعذر الاتصال بالخادم (${ApiClient.baseUrl})\nتأكد من اتصال الهاتف بنفس شبكة الخادم (Wi-Fi)',
        };
      }
      return {'success': false, 'error': 'خطأ في الاتصال بالخادم: $e'};
    }
  }

  static Future<List<AttendanceRecord>> getAttendance(
    String employeeId, {
    String? month,
    bool throwOnError = false,
  }) async {
    try {
      final query = <String, String>{'employeeId': employeeId};
      if (month != null) query['month'] = month;
      final response = await ApiClient.get(
        Uri.parse(ApiClient.attendance).replace(queryParameters: query),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map(
              (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      if (throwOnError) {
        throw Exception(_responseMessage(response.body, response.statusCode));
      }
      return [];
    } catch (e) {
      if (throwOnError) rethrow;
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final response = await ApiClient.get(
      Uri.parse('${ApiClient.baseUrl}/reference-data/leave-types'),
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
    final data = jsonDecode(response.body);
    if (data is! List) throw Exception('صيغة أنواع الإجازات غير صالحة');
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    final response = await ApiClient.get(
      Uri.parse('${ApiClient.leaves}/balance?employeeId=$employeeId'),
    );
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل رصيد الإجازات (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// يجلب كشف الراتب من الخادم إن توفّر، وإلا يبني تقديراً محلياً.
  ///
  /// العقد المتوقع من `GET /api/payroll?employeeId=X`:
  /// ```json
  /// {
  ///   "payPeriod": "أكتوبر 2026",
  ///   "approvedAt": "2026-10-18T13:02:00.000Z",  // null = غير معتمد
  ///   "baseSalary": 2200,
  ///   "allowances": [{"title": "بدل نقل", "amount": 200}],
  ///   "deductions": [{"title": "ضريبة (10%)", "amount": 220}]
  /// }
  /// ```
  /// أي غياب للنقطة (404) أو خطأ فيها يجعل التطبيق يعرض التقدير كما كان.
  static Future<PayrollSummary?> getPayroll(Employee employee) async {
    final remote = await _fetchRemotePayroll(employee.id);
    return remote;
  }

  static Future<PayrollSummary?> _fetchRemotePayroll(String employeeId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiClient.baseUrl}/payroll?employeeId=$employeeId'),
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final approvedAtText = data['approvedAt']?.toString().trim();
      final approvedAt = (approvedAtText != null && approvedAtText.isNotEmpty)
          ? DateTime.tryParse(approvedAtText)
          : null;

      final baseSalary = _readAmount(data, const [
            'baseSalary',
            'base_salary',
            'netSalary',
            'net_salary',
          ]) ??
          0.0;

      return PayrollSummary(
        payPeriod: data['payPeriod']?.toString().trim().isNotEmpty == true
            ? data['payPeriod'].toString()
            : DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
        isApproved: (data['isApproved'] == true || approvedAt != null),
        approvedAt: approvedAt,
        baseSalary: baseSalary,
        allowances: _readLineItems(data['allowances']),
        deductions: _readLineItems(data['deductions']),
      );
    } catch (_) {
      // خادم قديم أو مقطوع: نرجع للتقدير المحلي بدل أن تفشل الشاشة.
      return null;
    }
  }

  static PayrollSummary _estimatedPayroll(Employee employee) {
    final salary = employee.salary ?? 0;
    final deductions = <PayrollLineItem>[
      if (employee.subjectToTax)
        PayrollLineItem(
          title: 'الضريبة (${employee.taxRate}%)',
          amount: salary * employee.taxRate / 100,
        ),
      if (employee.subjectToInsurance)
        PayrollLineItem(
          title: 'الضمان (${employee.insuranceRate}%)',
          amount: salary * employee.insuranceRate / 100,
        ),
      if (employee.subjectToSolidarity)
        PayrollLineItem(
          title: 'التضامن (${employee.solidarityRate}%)',
          amount: salary * employee.solidarityRate / 100,
        ),
    ];
    return PayrollSummary(
      payPeriod: DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
      isApproved: false,
      baseSalary: salary,
      deductions: deductions,
    );
  }

  /// يقرأ مبالغ قد تصل كرقم أو كنص عشري (أعمدة DECIMAL من قاعدة البيانات).
  static double? _readAmount(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static List<PayrollLineItem> _readLineItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => PayrollLineItem(
            title: item['title']?.toString() ??
                item['label']?.toString() ??
                '',
            amount: _readAmount(item, const ['amount', 'value']) ?? 0,
          ),
        )
        .where((item) => item.title.isNotEmpty && item.amount != 0)
        .toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> getLeaveRequests({
    String? employeeId,
    String? managerId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (employeeId != null) queryParams['employeeId'] = employeeId;
      if (managerId != null) queryParams['managerId'] = managerId;

      final uri = Uri.parse(
        ApiClient.leaves,
      ).replace(queryParameters: queryParams);
      final response = await ApiClient.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> submitLeaveRequest({
    required String employeeId,
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    String? fileName,
    String? fileData,
  }) async {
    final response = await ApiClient.post(
      Uri.parse(ApiClient.leaves),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'type': type,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'fileName': fileName,
        'fileData': fileData,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
  }

  static String _responseMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'تعذر إكمال الطلب ($statusCode)';
      }
    } catch (_) {
      return 'تعذر إكمال الطلب ($statusCode)';
    }
    return 'تعذر إكمال الطلب ($statusCode)';
  }

  static Future<bool> updateLeaveRequest({
    required String requestId,
    required String status,
    required String approvedBy,
    required String managerId,
  }) async {
    try {
      final response = await ApiClient.put(
        Uri.parse(
          '${ApiClient.baseUrl}/portal-requests/leave/$requestId/review',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'approvedBy': approvedBy,
          'managerId': managerId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPermitRequests({
    String? employeeId,
    String? managerId,
  }) async {
    final queryParams = <String, String>{};
    if (employeeId != null) queryParams['employeeId'] = employeeId;
    if (managerId != null) queryParams['managerId'] = managerId;

    final uri = Uri.parse(
      '${ApiClient.leaves}/permits',
    ).replace(queryParameters: queryParams);
    final response = await ApiClient.get(uri);

    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> submitPermitRequest({
    required String employeeId,
    required String employeeName,
    required String managerId,
    required String type,
    required String date,
    required String time,
    required String reason,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiClient.leaves}/permits'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'managerId': managerId,
        'type': type,
        'date': date,
        'time': time,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<bool> updatePermitRequest({
    required String requestId,
    required String status,
    required String approvedBy,
    required String managerId,
  }) async {
    try {
      final response = await ApiClient.put(
        Uri.parse(
          '${ApiClient.baseUrl}/portal-requests/permit/$requestId/review',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'approvedBy': approvedBy,
          'managerId': managerId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSupportTickets(
    String employeeId,
  ) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiClient.support}?employeeId=$employeeId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> submitSupportTicket({
    required String employeeId,
    required String subject,
    required String details,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiClient.support),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'subject': subject,
          'details': details,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Employee>> getTeamMembers(String managerId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiClient.leaves}/team?managerId=$managerId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) => Employee.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPortalRequests({
    String? employeeId,
    String? managerId,
  }) async {
    final query = <String, String>{};
    if (employeeId != null) query['employeeId'] = employeeId;
    if (managerId != null) query['managerId'] = managerId;
    final response = await ApiClient.get(
      Uri.parse(
        '${ApiClient.baseUrl}/portal-requests',
      ).replace(queryParameters: query),
    );
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الطلبات (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  static Future<bool> reviewPortalRequest({
    required String type,
    required String requestId,
    required String managerId,
    required String status,
  }) async {
    final response = await ApiClient.put(
      Uri.parse('${ApiClient.baseUrl}/portal-requests/$type/$requestId/review'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'managerId': managerId, 'status': status}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> submitConsumableRequest({
    required String employeeId,
    required List<Map<String, dynamic>> items,
    required String reason,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiClient.baseUrl}/consumables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'items': items,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
    return true;
  }

  static Future<bool> submitMemoRequest({
    required String employeeId,
    required String subject,
    required String body,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiClient.baseUrl}/internal-memos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'subject': subject,
        'body': body,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getEvaluations(
    String employeeId,
  ) async {
    final response = await ApiClient.get(
      Uri.parse('${ApiClient.baseUrl}/evaluations?employeeId=$employeeId'),
    );
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل التقييمات (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  static Future<bool> submitEvaluationRequest(String employeeId) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiClient.baseUrl}/evaluations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employeeId': employeeId, 'year': DateTime.now().year}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// إرسال تقييم فعلي (درجة + ملاحظات) ليُحفظ في الخادم.
  /// كانت هذه العملية تُنفَّذ محلياً فقط داخل المزوّد، فتختفي الدرجة
  /// بمجرد تحديث الصفحة.
  static Future<bool> submitTeamEvaluation({
    required String employeeId,
    required int year,
    required double score,
    required String comment,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiClient.baseUrl}/evaluations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'year': year,
        'score': score,
        'comment': comment,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getAdvanceRequests({
    String? employeeId,
    String? managerId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (employeeId != null) queryParams['employeeId'] = employeeId;
      if (managerId != null) queryParams['managerId'] = managerId;

      final uri = Uri.parse(
        '${ApiClient.baseUrl}/advances',
      ).replace(queryParameters: queryParams);
      final response = await ApiClient.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitAdvanceRequest({
    required String employeeId,
    required double amount,
    required int installments,
    required String reason,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiClient.baseUrl}/advances'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'amount': amount,
        'installments': installments,
        'reason': reason,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_responseMessage(response.body, response.statusCode));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiClient.baseUrl}/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ??
            (response.statusCode == 200
                ? 'تم تغيير كلمة المرور بنجاح'
                : 'فشل تغيير كلمة المرور'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'تعذر الاتصال بالخادم: $e',
      };
    }
  }
}
