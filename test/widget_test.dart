import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:employee_portal_flutter/main.dart';
import 'package:employee_portal_flutter/providers/portal_provider.dart';

void main() {
  testWidgets('Employee portal app shows the redesigned login experience', (
    tester,
  ) async {
    await tester.pumpWidget(const EmployeePortalApp());

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('بوابة الموظف'), findsOneWidget);
    final textTheme = Theme.of(
      tester.element(find.text('بوابة الموظف')),
    ).textTheme;
    expect(textTheme.bodyMedium?.fontFamily, startsWith('Cairo'));
    expect(textTheme.titleLarge?.fontFamily, startsWith('Cairo'));
  });

  testWidgets('dashboard shows new services and bottom navigation', (
    tester,
  ) async {
    await _openHome(tester);

    expect(find.text('مخطط الأداء الأسبوعي'), findsNothing);
    expect(find.text('ملخص الأداء'), findsNothing);
    expect(find.text('راتبك'), findsOneWidget);
    expect(find.text('الغياب'), findsOneWidget);
    expect(find.text('الأذونات'), findsOneWidget);
    expect(find.text('المذكرة الداخلية'), findsOneWidget);
    expect(find.text('تقييم الأداء'), findsOneWidget);
    expect(find.text('الحضور'), findsOneWidget);
    expect(find.text('ملفي'), findsOneWidget);
  });

  testWidgets('absence card opens the employee attendance record', (
    tester,
  ) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('الغياب'));
    await tester.pumpAndSettle();

    expect(find.textContaining('يوم'), findsWidgets);
    await tester.tap(find.text('الغياب'));
    await tester.pumpAndSettle();
    expect(find.text('سجل الحضور'), findsOneWidget);
  });

  testWidgets('bottom navigation opens profile and attendance', (tester) async {
    await _openHome(tester);

    await tester.tap(find.text('ملفي'));
    await tester.pumpAndSettle();
    expect(find.text('المعلومات الشخصية'), findsOneWidget);

    await tester.tap(find.text('الحضور'));
    await tester.pumpAndSettle();
    expect(find.text('سجل الحضور'), findsOneWidget);
  });

  testWidgets('employee can submit a late-exit permit request', (tester) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('الأذونات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأذونات'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('خروج مبكر'));
    await tester.enterText(find.byType(TextField), 'موعد طبي');
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('تم إرسال طلب الإذن للمراجعة'), findsOneWidget);
    expect(find.text('موعد طبي'), findsOneWidget);
  });

  testWidgets('employee can request an annual evaluation', (tester) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('تقييم الأداء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تقييم الأداء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلب تقييم سنوي'));
    await tester.pumpAndSettle();

    expect(find.text('طلب التقييم السنوي قيد المراجعة'), findsOneWidget);
    expect(find.text('تم إرسال الطلب'), findsOneWidget);
  });

  testWidgets('approved payroll displays salary, allowances, and deductions', (
    tester,
  ) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('راتبك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('راتبك'));
    await tester.pumpAndSettle();

    expect(find.text('الراتب الأساسي'), findsOneWidget);
    expect(find.text('بدل السكن'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('التأمينات الاجتماعية'), 250);
    await tester.pumpAndSettle();
    expect(find.text('التأمينات الاجتماعية'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('صافي الراتب').last, 250);
    await tester.pumpAndSettle();
    expect(find.text('صافي الراتب'), findsWidgets);
  });

  testWidgets('employee can submit a leave request', (tester) async {
    await _openHome(tester);
    await tester.tap(find.text('الإجازات').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلب إجازة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'إجازة عائلية');
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('إجازة عائلية'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
  });

  testWidgets('employee can send an internal memo request', (tester) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('المذكرة الداخلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المذكرة الداخلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال طلب للمذكرة الداخلية'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'طلب تعميم');
    await tester.enterText(
      find.byType(TextField).at(1),
      'يرجى نشر موعد الاجتماع',
    );
    await tester.tap(find.text('إرسال'));
    await tester.pumpAndSettle();

    expect(find.text('طلب تعميم'), findsOneWidget);
    expect(find.text('يرجى نشر موعد الاجتماع'), findsOneWidget);
  });

  testWidgets('support screen lists old and newly submitted requests', (
    tester,
  ) async {
    await _openHome(tester);
    await tester.ensureVisible(find.text('الدعم'));
    await tester.pumpAndSettle();
    final portal = tester.element(find.text('الدعم')).read<PortalProvider>();
    expect(portal.employee?.id, '12345');
    expect(portal.mySupportTickets, hasLength(2));
    await tester.tap(find.text('الدعم'));
    await tester.pumpAndSettle();
    expect(find.text('الدعم الفني'), findsOneWidget);
    expect(find.textContaining('SUP-1048'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'مشكلة في الدخول');
    await tester.enterText(
      find.byType(TextField).at(1),
      'تعذر تسجيل الدخول إلى المنصة',
    );
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('مشكلة في الدخول'), findsOneWidget);
  });

  testWidgets('manager sees team approvals and evaluation actions', (
    tester,
  ) async {
    await _openHomeAs(tester, '1001');

    expect(find.text('موافقات الفريق'), findsOneWidget);
    expect(find.text('فريقي'), findsOneWidget);
    expect(find.text('أعضاء الفريق والتقييم السنوي'), findsOneWidget);
  });

  testWidgets('manager can approve and sign a team leave request', (
    tester,
  ) async {
    await _openHomeAs(tester, '1001');
    await tester.ensureVisible(find.text('موافقات الفريق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('موافقات الفريق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('موافقة وتوقيع').first);
    await tester.pumpAndSettle();

    expect(find.text('اعتماد: أحمد محمد'), findsWidgets);
  });

  testWidgets('manager can reject a team permit request', (tester) async {
    await _openHomeAs(tester, '1001');
    await tester.ensureVisible(find.text('موافقات الفريق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('موافقات الفريق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأذونات (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();

    expect(find.text('مرفوض'), findsOneWidget);
  });

  testWidgets('manager can submit a team member evaluation', (tester) async {
    await _openHomeAs(tester, '1001');
    await tester.ensureVisible(find.text('فريقي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فريقي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تقييم الموظف').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'أداء متميز وتعاون فعال');
    await tester.tap(find.text('إرسال التقييم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التقييمات المرسلة'));
    await tester.pumpAndSettle();

    expect(find.text('سارة خالد'), findsOneWidget);
    expect(find.text('أداء متميز وتعاون فعال'), findsOneWidget);
  });
}

Future<void> _openHome(WidgetTester tester) async {
  await _openHomeAs(tester, '1002');
}

Future<void> _openHomeAs(WidgetTester tester, String employeeNumber) async {
  await tester.pumpWidget(const EmployeePortalApp());
  await tester.pumpAndSettle();
  final context = tester.element(find.text('تسجيل الدخول'));
  final login = context.read<PortalProvider>().login(
    identifier: employeeNumber,
    password: '123456',
  );
  await tester.pump(const Duration(seconds: 3));
  await login;
  await tester.pumpAndSettle();
  Navigator.of(context).pushReplacementNamed('/home');
  await tester.pumpAndSettle();
}
