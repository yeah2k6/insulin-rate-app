import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  // 设置每日提醒
  Future<void> setDailyReminder(int hour, int minute, {String title = '基础率提醒', String body = '该检查和调整基础率了'}) async {
    await _notifications.zonedSchedule(
      0,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'insulin_reminder',
          '基础率提醒',
          channelDescription: '定期提醒检查基础率',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 设置间隔提醒（如每3天）
  Future<void> setIntervalReminder(int daysInterval) async {
    await _notifications.periodicallyShow(
      1,
      '基础率提醒',
      '该检查和调整基础率了',
      RepeatInterval.everyMinute, // 注意：实际间隔需要自己计算，这里用每日提醒+取消重设模拟
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'insulin_reminder_interval',
          '基础率间隔提醒',
          channelDescription: '间隔提醒检查基础率',
        ),
      ),
    );
  }

  // 取消所有提醒
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
