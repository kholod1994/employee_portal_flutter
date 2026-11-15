/// نماذج كشف الراتب.
///
/// المبالغ كلها `double` لأن قاعدة البيانات تُخزّن الأعمدة المالية
/// كـ DECIMAL (مثال: `2200.0000`)، وأي تقسيم بنسبة مئوية
/// (ضريبة/ضمان/تضامن) ينتج قيمة عشريّة لا يصحّ قصّها إلى int.
class PayrollLineItem {
  final String title;
  final double amount;

  const PayrollLineItem({required this.title, required this.amount});
}

class PayrollSummary {
  final String payPeriod;
  final bool isApproved;
  final double baseSalary;
  final List<PayrollLineItem> allowances;
  final List<PayrollLineItem> deductions;
  final DateTime? approvedAt;

  const PayrollSummary({
    required this.payPeriod,
    required this.isApproved,
    required this.baseSalary,
    this.allowances = const [],
    this.deductions = const [],
    this.approvedAt,
  });

  double get totalAllowances =>
      allowances.fold(0, (total, item) => total + item.amount);

  double get totalDeductions =>
      deductions.fold(0, (total, item) => total + item.amount);

  double get netSalary => baseSalary + totalAllowances - totalDeductions;
}
