/// نموذج سجل الحضور والانصراف.
///
/// شاشة الحضور تقرأ `status` و`date` و`checkIn` و`checkOut` فقط،
/// والقراءة هنا متسامحة مع صيغ الخادم المختلفة
/// (camelCase أو snake_case، وتاريخ ISO أو نص جاهز للعرض).
class AttendanceRecord {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status; // present | late | absent ...

  const AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  bool get isPresent => status == 'present';

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: _readText(json, const ['date', 'attendanceDate', 'day']) ?? '—',
      checkIn: _readText(json, const [
        'checkIn',
        'check_in',
        'checkInTime',
        'check_in_time',
        'entryTime',
      ]),
      checkOut: _readText(json, const [
        'checkOut',
        'check_out',
        'checkOutTime',
        'check_out_time',
        'exitTime',
      ]),
      status: _readText(json, const ['status', 'attendanceStatus']) ?? 'absent',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'status': status,
      };
}

String? _readText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') continue;
    return text;
  }
  return null;
}
