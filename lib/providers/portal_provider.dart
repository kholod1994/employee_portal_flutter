import 'dart:async';

import 'package:flutter/foundation.dart';
import '../core/storage/safe_storage.dart';

import '../core/network/api_client.dart';
import '../models/app_notification.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/payroll.dart';
import '../models/workflow_request.dart';
import '../models/nav_bar_style.dart';
import '../services/api_service.dart';
import '../services/app_notification_service.dart';

class PortalProvider extends ChangeNotifier {
  Employee? _employee;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  List<AttendanceRecord> _attendance = const [];
  List<Map<String, dynamic>> _leaveTypes = const [];
  String? _leaveTypesError;
  final _storage = const SafeStorage();
  Map<String, int> _leaveBalance = const {
    'annual': 15,
    'used': 5,
    'remaining': 10,
  };
  List<Map<String, dynamic>> _leaveTypeBalances = const [];
  PayrollSummary? _payrollSummary;
  final List<Employee> _teamMembers = [];
  final List<LeaveRequest> _leaveRequests = [];
  final List<PermitRequest> _permitRequests = [];
  final List<MemoRequest> _memoRequests = [];
  List<PortalRequest> _myPortalRequests = const [];
  final List<SupportTicket> _supportTickets = [];
  final List<AdvanceRequest> _advanceRequests = [];
  final List<TeamEvaluation> _teamEvaluations = [];
  List<PortalRequest> _teamRequests = const [];
  List<AppNotification> _notifications = const [];
  final Set<String> _shownNotificationIds = {};
  NavBarStyle _navBarStyle = NavBarStyle.neonWave;
  NavBarStyle get navBarStyle => _navBarStyle;

  PortalProvider() {
    loadNavBarStyle();
  }

  Future<void> setNavBarStyle(NavBarStyle style) async {
    _navBarStyle = style;
    notifyListeners();
    try {
      await _storage.write(key: 'nav_bar_style', value: style.name);
    } catch (_) {}
  }

  Future<void> loadNavBarStyle() async {
    try {
      final saved = await _storage.read(key: 'nav_bar_style');
      if (saved != null) {
        _navBarStyle = NavBarStyle.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => NavBarStyle.neonWave,
        );
        notifyListeners();
      }
    } catch (_) {}
  }
  Timer? _notificationTimer;

  Employee? get employee => _employee;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  List<AttendanceRecord> get attendance => _attendance;
  List<Map<String, dynamic>> get leaveTypes => List.unmodifiable(_leaveTypes);
  String? get leaveTypesError => _leaveTypesError;
  Map<String, int> get leaveBalance => _leaveBalance;
  List<Map<String, dynamic>> get leaveTypeBalances =>
      List.unmodifiable(_leaveTypeBalances);
  PayrollSummary? get payrollSummary => _payrollSummary;
  int get absenceDays =>
      _attendance.where((record) => record.status == 'absent').length;
  int get lateDays =>
      _attendance.where((record) => record.status == 'late').length;
  // لائحة النظام المحدثة: كل 3 أيام تأخير = 1 يوم غياب جزاء
  int get delayPenaltyDays => lateDays ~/ 3;
  int get totalDeductionDays => absenceDays + delayPenaltyDays;
  bool get isManager => _employee?.isManager ?? false;
  List<Employee> get teamMembers => List.unmodifiable(_teamMembers);
  List<LeaveRequest> get myLeaveRequests => _leaveRequests
      .where((request) => request.employeeId == _employee?.id)
      .toList(growable: false);
  List<LeaveRequest> get teamLeaveRequests => _leaveRequests
      .where((request) => request.managerId == _employee?.id)
      .toList(growable: false);
  List<PermitRequest> get myPermitRequests => _permitRequests
      .where((request) => request.employeeId == _employee?.id)
      .toList(growable: false);
  List<PermitRequest> get teamPermitRequests => _permitRequests
      .where((request) => request.managerId == _employee?.id)
      .toList(growable: false);
  List<MemoRequest> get myMemoRequests => _memoRequests
      .where((request) => request.employeeId == _employee?.id)
      .toList(growable: false);
  List<SupportTicket> get mySupportTickets => _supportTickets
      .where((ticket) => ticket.employeeId == _employee?.id)
      .toList(growable: false);
  List<TeamEvaluation> get teamEvaluations =>
      List.unmodifiable(_teamEvaluations);
  List<PortalRequest> get teamRequests => List.unmodifiable(_teamRequests);
  List<PortalRequest> get myConsumableRequests => _myPortalRequests
      .where((request) => request.type == 'consumable')
      .toList(growable: false);

  /// مذكرات ومستهلكات التابعين لفريق المدير الحالي
  /// (`_teamRequests` تُحمَّل من `/portal-requests?managerId=` وتضم كل الأنواع)
  List<PortalRequest> get teamMemoRequests => _teamRequests
      .where((request) => request.type == 'memo')
      .toList(growable: false);
  List<AdvanceRequest> get myAdvanceRequests => List.unmodifiable(_advanceRequests);
  List<PortalRequest> get teamAdvanceRequests => _teamRequests
      .where((request) => request.type == 'advance')
      .toList(growable: false);
  List<PortalRequest> get teamConsumableRequests => _teamRequests
      .where((request) => request.type == 'consumable')
      .toList(growable: false);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> loadAttendanceForMonth(DateTime month) async {
    final employee = _employee;
    if (employee == null) return;
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    _attendance = await ApiService.getAttendance(
      employee.id,
      month: monthKey,
      throwOnError: true,
    );
    notifyListeners();
  }

  Future<void> submitLeaveRequest({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? fileName,
    String? fileData,
  }) async {
    final employee = _employee;
    if (employee == null) throw Exception('تعذر تحديد الموظف المسجل دخوله');

    await ApiService.submitLeaveRequest(
      employeeId: employee.id,
      type: type,
      startDate: startDate.toIso8601String().split('T')[0],
      endDate: endDate.toIso8601String().split('T')[0],
      reason: reason,
      fileName: fileName,
      fileData: fileData,
    );

    await _reloadOwnLeaveRequests();
    notifyListeners();
  }

  Future<void> _reloadOwnLeaveRequests() async {
    final employee = _employee;
    if (employee == null) return;
    final leaveRequestsData = await ApiService.getLeaveRequests(
      employeeId: employee.id,
    );
    _leaveRequests
      ..clear()
      ..addAll(
        leaveRequestsData.map(
          (data) => LeaveRequest(
            id: data['id']?.toString() ?? '',
            employeeId: data['employeeId']?.toString() ?? '',
            employeeName: data['employeeName']?.toString() ?? '',
            managerId: employee.id,
            type:
                data['type']?.toString() ?? data['typeName']?.toString() ?? '',
            startDate:
                DateTime.tryParse(data['startDate']?.toString() ?? '') ??
                DateTime.now(),
            endDate:
                DateTime.tryParse(data['endDate']?.toString() ?? '') ??
                DateTime.now(),
            reason: data['reason']?.toString() ?? '',
            status: _parseRequestStatus(data['status']?.toString()),
            approvedBy: data['approvedBy']?.toString(),
            submittedAt: DateTime.tryParse(
              data['submittedAt']?.toString() ?? '',
            ),
            fileName: data['fileName']?.toString(),
            fileData: data['fileData']?.toString(),
          ),
        ),
      );
    await _syncLeaveEndReminders(employee.id);
  }

  Future<void> _syncLeaveEndReminders(String employeeId) async {
    final employeeLeaves = _leaveRequests.where(
      (request) => request.employeeId == employeeId,
    );
    for (final request in employeeLeaves) {
      if (request.status == RequestStatus.approved) {
        await AppNotificationService.scheduleLeaveEnd(
          leaveId: request.id,
          endDate: request.endDate,
        );
      } else {
        await AppNotificationService.cancelLeaveEnd(request.id);
      }
    }
  }

  Future<void> refreshNotifications() => _refreshNotifications();

  Future<void> _refreshNotifications() async {
    final employee = _employee;
    if (employee == null) return;
    try {
      final data = await ApiService.getEmployeeNotifications(employee.id);
      final incoming = data
          .map(AppNotification.fromJson)
          .toList(growable: false);
      _notifications = incoming;
      for (final notification in incoming) {
        if (notification.id.isEmpty ||
            !_shownNotificationIds.add(notification.id)) {
          continue;
        }
        await AppNotificationService.showDecision(
          id: notification.id,
          title: notification.title,
          body: notification.message,
        );
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Unable to refresh employee notifications: $error');
    }
  }

  Future<void> markNotificationRead(AppNotification notification) async {
    final employee = _employee;
    if (employee == null) return;
    await ApiService.markEmployeeNotificationRead(
      employeeId: employee.id,
      notificationId: notification.id,
    );
    _notifications = _notifications
        .where((item) => item.id != notification.id)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final employee = _employee;
    if (employee == null) return;
    await ApiService.markAllEmployeeNotificationsRead(employee.id);
    _notifications = const [];
    notifyListeners();
  }

  void _startNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshNotifications(),
    );
  }

  bool get _canReview => isManager;

  Future<void> reviewLeaveRequest({
    required String requestId,
    required RequestStatus status,
  }) async {
    final managerName = _employee?.name;
    if (!_canReview || managerName == null) return;
    final success = await ApiService.updateLeaveRequest(
      requestId: requestId,
      status: _requestStatusToString(status),
      approvedBy: managerName,
      managerId: _employee!.id,
    );

    if (success) {
      await _reloadTeamRequests();
      notifyListeners();
    }
  }

  Future<bool> submitPermitRequest({
    required String type,
    required DateTime date,
    required String time,
    required String reason,
  }) async {
    final employee = _employee;
    if (employee == null) return false;

    final request = await ApiService.submitPermitRequest(
      employeeId: employee.id,
      employeeName: employee.name,
      managerId: employee.managerId,
      type: type,
      date: date.toIso8601String().split('T')[0],
      time: time,
      reason: reason,
    );

    _permitRequests.removeWhere((item) => item.id == request['id']?.toString());
    _permitRequests.insert(0, _permitRequestFromJson(request));
    notifyListeners();
    return true;
  }

  Future<bool> submitAdvanceRequest({
    required double amount,
    required int installments,
    required String reason,
  }) async {
    final employee = _employee;
    if (employee == null) return false;

    try {
      final res = await ApiService.submitAdvanceRequest(
        employeeId: employee.id,
        amount: amount,
        installments: installments,
        reason: reason,
      );
      await loadMyAdvanceRequests();
      await _reloadTeamRequests();
      return res['success'] == true;
    } catch (e) {
      debugPrint('Error submitting advance: $e');
      return false;
    }
  }

  Future<void> loadMyAdvanceRequests() async {
    final employee = _employee;
    if (employee == null) return;
    try {
      final data = await ApiService.getAdvanceRequests(employeeId: employee.id);
      _advanceRequests
        ..clear()
        ..addAll(data.map(AdvanceRequest.fromJson));
      notifyListeners();
    } catch (error) {
      debugPrint('Unable to load advance requests: $error');
    }
  }

  Future<void> loadMyPermitRequests() async {
    final employee = _employee;
    if (employee == null) return;
    final permitRequestsData = await ApiService.getPermitRequests(
      employeeId: employee.id,
    );
    _permitRequests
      ..removeWhere((request) => request.employeeId == employee.id)
      ..addAll(permitRequestsData.map(_permitRequestFromJson));
    notifyListeners();
  }

  Future<void> loadTeamRequests() async {
    await _reloadTeamLeaveAndPermitRequests();
    notifyListeners();
  }

  Future<void> _reloadTeamLeaveAndPermitRequests() async {
    final employee = _employee;
    if (employee == null || !employee.isManager) return;

    try {
      final teamLeaveData = await ApiService.getLeaveRequests(
        managerId: employee.id,
      );
      _leaveRequests
        ..removeWhere((request) => request.managerId == employee.id)
        ..addAll(
          teamLeaveData.map(
            (data) => LeaveRequest(
              id: data['id']?.toString() ?? '',
              employeeId: data['employeeId']?.toString() ?? '',
              employeeName: data['employeeName']?.toString() ?? '',
              managerId: data['managerId']?.toString() ?? '',
              type:
                  data['type']?.toString() ??
                  data['typeName']?.toString() ??
                  '',
              startDate:
                  DateTime.tryParse(data['startDate']?.toString() ?? '') ??
                  DateTime.now(),
              endDate:
                  DateTime.tryParse(data['endDate']?.toString() ?? '') ??
                  DateTime.now(),
              reason: data['reason']?.toString() ?? '',
              status: _parseRequestStatus(data['status']?.toString()),
              approvedBy: data['approvedBy']?.toString(),
              submittedAt: DateTime.tryParse(
                data['submittedAt']?.toString() ?? '',
              ),
              fileName: data['fileName']?.toString(),
              fileData: data['fileData']?.toString(),
            ),
          ),
        );
    } catch (error) {
      debugPrint('Unable to load team leave requests: $error');
    }

    try {
      final teamPermitData = await ApiService.getPermitRequests(
        managerId: employee.id,
      );
      _permitRequests
        ..removeWhere((request) => request.managerId == employee.id)
        ..addAll(teamPermitData.map(_permitRequestFromJson));
    } catch (error) {
      debugPrint('Unable to load team permit requests: $error');
    }
  }

  PermitRequest _permitRequestFromJson(Map<String, dynamic> data) {
    return PermitRequest(
      id: data['id']?.toString() ?? '',
      employeeId: data['employeeId']?.toString() ?? '',
      employeeName: data['employeeName']?.toString() ?? '',
      managerId: data['managerId']?.toString() ?? '',
      type: data['typeName']?.toString() ?? data['type']?.toString() ?? '',
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      time: data['time']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      status: _parseRequestStatus(data['status']?.toString()),
      approvedBy: data['approvedBy']?.toString(),
      submittedAt: DateTime.tryParse(data['submittedAt']?.toString() ?? ''),
    );
  }

  Future<void> reviewPermitRequest({
    required String requestId,
    required RequestStatus status,
  }) async {
    final managerName = _employee?.name;
    if (!_canReview || managerName == null) return;
    final success = await ApiService.updatePermitRequest(
      requestId: requestId,
      status: _requestStatusToString(status),
      approvedBy: managerName,
      managerId: _employee!.id,
    );

    if (success) {
      await _reloadTeamRequests();
      notifyListeners();
    }
  }

  Future<bool> reviewPortalRequest(
    PortalRequest request,
    RequestStatus status,
  ) async {
    final employee = _employee;
    if (!_canReview || employee == null) return false;
    final success = await ApiService.reviewPortalRequest(
      type: request.type,
      requestId: request.id,
      managerId: employee.id,
      status: _requestStatusToString(status),
    );
    if (success) {
      await _reloadTeamRequests();
      notifyListeners();
    }
    return success;
  }

  Future<void> _reloadTeamRequests() async {
    final employee = _employee;
    if (employee == null || !employee.isManager) {
      _teamRequests = const [];
      _teamEvaluations.clear();
      return;
    }
    final requests = await ApiService.getPortalRequests(managerId: employee.id);
    _teamRequests = requests
        .map(PortalRequest.fromJson)
        .toList(growable: false);

    // تبويب «التقييمات المرسلة» يقرأ من الخادم الآن، حتى تبقى التقييمات
    // بعد إعادة الدخول أو تحديث الصفحة (كانت تُحفظ محلياً فقط فتضيع).
    _teamEvaluations
      ..clear()
      ..addAll(
        requests
            .where((item) => item['type']?.toString() == 'evaluation')
            .map(TeamEvaluation.fromJson)
            .toList(growable: false),
      );
  }

  Future<bool> submitMemoRequest({
    required String subject,
    required String body,
  }) async {
    final employee = _employee;
    if (employee == null) return false;
    final success = await ApiService.submitMemoRequest(
      employeeId: employee.id,
      subject: subject,
      body: body,
    );
    if (!success) return false;
    _memoRequests.insert(
      0,
      MemoRequest(
        id: _newRequestId('memo'),
        employeeId: employee.id,
        employeeName: employee.name,
        subject: subject,
        body: body,
        submittedAt: DateTime.now(),
      ),
    );
    await _reloadMyPortalRequests();
    notifyListeners();
    return true;
  }

  Future<bool> submitConsumableRequest({
    required List<Map<String, dynamic>> items,
    required String reason,
  }) async {
    final employee = _employee;
    if (employee == null) return false;
    final success = await ApiService.submitConsumableRequest(
      employeeId: employee.id,
      items: items,
      reason: reason,
    );
    if (success) {
      await _reloadMyPortalRequests();
      if (employee.isManager) await _reloadTeamRequests();
    }
    return success;
  }

  Future<void> _reloadMyPortalRequests() async {
    final employee = _employee;
    if (employee == null) {
      _myPortalRequests = const [];
      return;
    }
    final requests = await ApiService.getPortalRequests(
      employeeId: employee.id,
    );
    _myPortalRequests = requests
        .map(PortalRequest.fromJson)
        .toList(growable: false);
    _memoRequests
      ..clear()
      ..addAll(
        _myPortalRequests
            .where((request) => request.type == 'memo')
            .map(
              (request) => MemoRequest(
                id: request.id,
                employeeId: request.employeeId,
                employeeName: request.employeeName,
                subject: request.title,
                body: request.details,
                statusLabel: request.statusLabel,
                submittedAt: DateTime.tryParse(request.date) ?? DateTime.now(),
              ),
            ),
      );
  }

  Future<void> submitSupportTicket({
    required String subject,
    required String details,
  }) async {
    final employee = _employee;
    if (employee == null) return;

    final success = await ApiService.submitSupportTicket(
      employeeId: employee.id,
      subject: subject,
      details: details,
    );

    if (success) {
      // Reload support tickets from API
      final supportTicketsData = await ApiService.getSupportTickets(
        employee.id,
      );
      _supportTickets.clear();
      for (final data in supportTicketsData) {
        _supportTickets.add(
          SupportTicket(
            id: data['id']?.toString() ?? '',
            employeeId: data['employeeId']?.toString() ?? '',
            subject: data['subject']?.toString() ?? '',
            details: data['details']?.toString() ?? '',
            response: data['response']?.toString(),
            status: _parseRequestStatus(data['status']?.toString()),
            submittedAt: data['submittedAt'] != null
                ? DateTime.parse(data['submittedAt'].toString())
                : DateTime.now(),
          ),
        );
      }
      notifyListeners();
    }
  }

  /// يحفظ تقييم الموظف في الخادم ثم يحدّث القائمة المحلية.
  /// كانت هذه العملية محلية فقط (تُدرج في القائمة وتنتهي)، فتختفي الدرجة
  /// بمجرد تحديث الصفحة أو إعادة الدخول.
  Future<bool> submitTeamEvaluation({
    required String employeeId,
    required double score,
    required String comment,
  }) async {
    if (!_canReview) return false;
    final member = _teamMembers
        .where((item) => item.id == employeeId)
        .firstOrNull;
    if (member == null) return false;

    final year = DateTime.now().year;
    final saved = await ApiService.submitTeamEvaluation(
      employeeId: employeeId,
      year: year,
      score: score,
      comment: comment,
    );
    if (!saved) return false;

    _teamEvaluations.insert(
      0,
      TeamEvaluation(
        id: _newRequestId('review'),
        employeeId: member.id,
        employeeName: member.name,
        year: year,
        score: score,
        comment: comment,
        submittedAt: DateTime.now(),
      ),
    );
    await _reloadTeamRequests();
    notifyListeners();
    return true;
  }

  String _newRequestId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(identifier, password);
      if (result['success'] != true) {
        _isAuthenticated = false;
        _employee = null;
        return result;
      }

      _employee = Employee.fromJson(result['employee'] as Map<String, dynamic>);
      _isAuthenticated = true;
      final currentMonth = DateTime.now();
      _attendance = await ApiService.getAttendance(
        _employee!.id,
        month:
            '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}',
      );
      final leaveResult = await ApiService.getLeaveBalance(_employee!.id);
      _leaveTypeBalances =
          (leaveResult['leaveTypes'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      _leaveBalance = {
        'annual': (leaveResult['annual'] as num?)?.round() ?? 0,
        'used': (leaveResult['used'] as num?)?.round() ?? 0,
        'remaining': (leaveResult['remaining'] as num?)?.round() ?? 0,
      };
      _payrollSummary = await ApiService.getPayroll(_employee!);

      final profileData = await ApiService.getEmployeeProfile(_employee!.id);
      if (profileData != null) _employee = Employee.fromJson(profileData);

      await _reloadOwnLeaveRequests();
      await _refreshNotifications();
      _startNotificationPolling();
      try {
        _leaveTypes = await ApiService.getLeaveTypes();
        _leaveTypesError = null;
      } catch (error) {
        _leaveTypes = const [];
        _leaveTypesError = error.toString();
      }

      try {
        final permitRequestsData = await ApiService.getPermitRequests(
          employeeId: _employee!.id,
        );
        _permitRequests
          ..removeWhere((request) => request.employeeId == _employee!.id)
          ..addAll(permitRequestsData.map(_permitRequestFromJson));
      } catch (error) {
        debugPrint('Unable to load employee permit requests: $error');
      }

      final supportTicketsData = await ApiService.getSupportTickets(
        _employee!.id,
      );
      _supportTickets
        ..clear()
        ..addAll(
          supportTicketsData.map(
            (data) => SupportTicket(
              id: data['id']?.toString() ?? '',
              employeeId: data['employeeId']?.toString() ?? '',
              subject: data['subject']?.toString() ?? '',
              details: data['details']?.toString() ?? '',
              response: data['response']?.toString(),
              status: _parseRequestStatus(data['status']?.toString()),
              submittedAt:
                  DateTime.tryParse(data['submittedAt']?.toString() ?? '') ??
                  DateTime.now(),
            ),
          ),
        );

      await _reloadMyPortalRequests();
      if (_employee!.isManager) {
        final teamData = await ApiService.getTeamMembers(_employee!.id);
        _teamMembers
          ..clear()
          ..addAll(teamData);
        await _reloadTeamRequests();
        await _reloadTeamLeaveAndPermitRequests();
      } else {
        _teamRequests = const [];
        _myPortalRequests = const [];
      }
      return result;
    } catch (error) {
      await ApiClient.clearToken();
      _isAuthenticated = false;
      _employee = null;
      _teamRequests = const [];
      return {'success': false, 'error': error.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RequestStatus _parseRequestStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'موافق عليها':
      case 'موافق عليه':
        return RequestStatus.approved;
      case 'rejected':
      case 'مرفوض':
      case 'مرفوضة':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }

  String _requestStatusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.approved:
        return 'approved';
      case RequestStatus.rejected:
        return 'rejected';
      default:
        return 'pending';
    }
  }

  Future<void> logout() async {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    await ApiClient.clearToken();
    await _storage.delete(key: 'employeeNumber');
    await _storage.delete(key: 'password');
    await _storage.delete(key: 'rememberMe');

    _employee = null;
    _isAuthenticated = false;
    _attendance = const [];
    _leaveBalance = const {'annual': 15, 'used': 5, 'remaining': 10};
    _payrollSummary = null;
    _teamRequests = const [];
    _notifications = const [];
    _shownNotificationIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
