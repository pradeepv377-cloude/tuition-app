import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationService._();

  static const int _reminderNotificationId = 1001;
  static const String _dayKey = 'reminder_day';

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMonthlyReminder(int dayOfMonth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dayKey, dayOfMonth);

    await _plugin.cancel(_reminderNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth,
      9,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        dayOfMonth,
        9,
        0,
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'fee_reminder',
      'Fee Reminders',
      channelDescription: 'Monthly fee collection reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.zonedSchedule(
      _reminderNotificationId,
      'Fee Collection Reminder',
      'Tap to send WhatsApp reminders to all parents',
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_reminderNotificationId);
  }

  Future<int?> getSavedReminderDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dayKey);
  }
}
