import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'employee_portal_updates';
  static bool _initialized = false;
  static bool _timezoneReady = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'تنبيهات الموظف',
      channelDescription: 'إشعارات الرواتب، السلف، وموافقات الإجازات والأذونات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static Future<void> initialize() async {
    if (!_supported || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      _timezoneReady = true;
    } catch (error) {
      debugPrint('Unable to determine the device timezone: $error');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    await initialize();
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return result ?? true;
  }

  static Future<void> showDecision({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await initialize();
    if (!_initialized) return;
    await _plugin.show(
      id: _stableId(id),
      title: title,
      body: body,
      notificationDetails: _notificationDetails,
      payload: id,
    );
  }

  static Future<void> scheduleLeaveEnd({
    required String leaveId,
    required DateTime endDate,
  }) async {
    if (!_supported || !_timezoneReady) return;
    await initialize();
    if (!_initialized || !_timezoneReady) return;

    final scheduledDate = tz.TZDateTime(
      tz.local,
      endDate.year,
      endDate.month,
      endDate.day,
      9,
    );
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      await cancelLeaveEnd(leaveId);
      return;
    }

    await _plugin.zonedSchedule(
      id: _stableId('leave-end:$leaveId'),
      title: 'تنبيه انتهاء الإجازة',
      body: 'تنتهي إجازتك المعتمدة اليوم. نأمل مباشرة العمل في الموعد المحدد.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'leave-end:$leaveId',
    );
  }

  static Future<void> cancelLeaveEnd(String leaveId) async {
    if (!_supported) return;
    await initialize();
    if (!_initialized) return;
    await _plugin.cancel(id: _stableId('leave-end:$leaveId'));
  }

  static int _stableId(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}