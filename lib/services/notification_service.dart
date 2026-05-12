import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleSessionReminder({
    required int id,
    required String thesisTitle,
    required DateTime sessionTime,
  }) async {
    final fireAt = sessionTime.subtract(const Duration(hours: 1));
    if (fireAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      'Session Reminder',
      'Guidance session for "$thesisTitle" starts in 1 hour.',
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sessions',
          'Session Reminders',
          channelDescription: 'Reminders before guidance sessions',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleMilestoneReminder({
    required int id,
    required String title,
    required DateTime dueDate,
  }) async {
    final fireAt = dueDate.subtract(const Duration(days: 1));
    if (fireAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      'Milestone Due Tomorrow',
      '"$title" is due tomorrow.',
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Milestone Reminders',
          channelDescription: 'Reminders for upcoming milestones',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleBimbinganReminders({
    required String bimbinganId,
    required String title,
    required DateTime dateTime,
  }) async {
    final base = bimbinganId.hashCode.abs();
    final reminders = [
      (base, dateTime.subtract(const Duration(days: 1)), '1 hari lagi'),
      (base + 10000, dateTime.subtract(const Duration(hours: 3)), '3 jam lagi'),
      (base + 20000, dateTime.subtract(const Duration(hours: 1)), '1 jam lagi'),
    ];
    for (final r in reminders) {
      if (r.$2.isBefore(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        r.$1,
        'Pengingat Bimbingan',
        '"$title" dimulai ${r.$3}.',
        tz.TZDateTime.from(r.$2, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bimbingan',
            'Pengingat Bimbingan',
            channelDescription: 'Reminder sebelum sesi bimbingan',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelBimbinganReminders(String bimbinganId) async {
    final base = bimbinganId.hashCode.abs();
    await _plugin.cancel(base);
    await _plugin.cancel(base + 10000);
    await _plugin.cancel(base + 20000);
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
}
