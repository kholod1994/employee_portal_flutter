import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/payroll.dart';

class MockBackend {
  static final Employee _mockEmployee = Employee(
    id: '12345',
    name: 'أحمد محمد',
    email: 'ahmed@example.com',
    department: 'تقنية المعلومات',
    position: 'مطور برمجيات',
    managerId: '10001',
  );

  static final List<AttendanceRecord> _mockAttendance = [
    AttendanceRecord(
      date: '2026-10-01',
      status: 'present',
      checkIn: '08:30',
      checkOut: '17:00',
    ),
    AttendanceRecord(
      date: '2026-10-02',
      status: 'present',
      checkIn: '08:45',
      checkOut: null,
    ),
    AttendanceRecord(
      date: '2026-09-30',
      status: 'late',
      checkIn: '09:15',
      checkOut: '17:30',
    ),
  ];

  static Future<Map<String, dynamic>> login(
    String employeeNumber,
    String password,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    if (employeeNumber == '1002' && password == '123456') {
      return {
        'success': true,
        'employee': _mockEmployee.toJson(),
      };
    }
    if (employeeNumber == '1001' && password == '123456') {
      return {
        'success': true,
        'employee': Employee(
          id: '10001',
          name: 'أحمد محمد',
          email: 'ahmed@example.com',
          department: 'تقنية المعلومات',
          position: 'مدير',
          managerId: '10000',
          role: 'manager',
        ).toJson(),
      };
    }

    return {
      'success': false,
      'error': 'بيانات الدخول غير صحيحة',
    };
  }

  static Future<List<AttendanceRecord>> getAttendance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockAttendance;
  }

  static Future<Map<String, dynamic>> getLeaveBalance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'annual': 15,
      'used': 5,
      'remaining': 10,
    };
  }

  static Future<PayrollSummary> getPayroll() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return PayrollSummary(
      payPeriod: 'أكتوبر 2026',
      isApproved: true,
      baseSalary: 11000,
      allowances: const [
        PayrollLineItem(title: 'بدل السكن', amount: 2500),
        PayrollLineItem(title: 'بدل النقل', amount: 800),
      ],
      deductions: const [
        PayrollLineItem(title: 'التأمينات الاجتماعية', amount: 1000),
        PayrollLineItem(title: 'قسط تمويل', amount: 250),
      ],
      approvedAt: DateTime(2026, 10, 1),
    );
  }
}
