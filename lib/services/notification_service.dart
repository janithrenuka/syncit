import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // TODO: Handle notification tap
      },
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String recurrence = 'None',
    List<int>? weekdays,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    if (tzScheduledDate.isBefore(now)) {
      if (recurrence == 'None') {
        // If it's a one-time event in the past, don't schedule or show immediately?
        // For now, let's just add a small delay to make it valid if it's very close,
        // or effectively ignore it / show now.
        // But user picked a date. If they picked past date, maybe they want to log it?
        // Let's assume they picked a future date or we adjust.
        // Actually, if it's 'Daily' etc, we need to move to next occurrence.
      }
    }

    // Adjust for recurring
    if (recurrence != 'None' && tzScheduledDate.isBefore(now)) {
      // Logic to move to next occurrence would be here, but matchDateTimeComponents handles strict repetition based on components.
      // We just need to make sure the *first* trigger is in the future effectively if we rely on the component matching
      // starting from the provided date.
      // Actually, zonedSchedule with matchDateTimeComponents calculates the next instance based on the components.
      // But the 'scheduledDate' must be the baseline.
    }

    if (recurrence == 'Weekly' && weekdays != null && weekdays.isNotEmpty) {
      // Schedule for each selected day
      for (final day in weekdays) {
        // Calculate next occurrence of this specific weekday
        tz.TZDateTime nextInstance = _nextInstanceOfDay(day, tzScheduledDate);

        // Unique ID for each day: generic ID + day index (1-7)
        // Ensure within 32-bit integer range
        final notificationId = (id + day) & 0x7FFFFFFF;

        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          nextInstance,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders_channel',
              'Reminders',
              channelDescription: 'Channel for Reminder Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return;
    }

    // For Daily, Monthly, Yearly, None
    DateTimeComponents? matchComponent;
    if (recurrence == 'Daily') {
      matchComponent = DateTimeComponents.time;
      // Ensure scheduled time is in future for the first trigger
      while (tzScheduledDate.isBefore(now)) {
        tzScheduledDate = tzScheduledDate.add(const Duration(days: 1));
      }
    } else if (recurrence == 'Monthly') {
      matchComponent = DateTimeComponents.dayOfMonthAndTime;
      while (tzScheduledDate.isBefore(now)) {
        tzScheduledDate = tz.TZDateTime(
          tz.local,
          tzScheduledDate.year,
          tzScheduledDate.month + 1,
          tzScheduledDate.day,
          tzScheduledDate.hour,
          tzScheduledDate.minute,
        );
      }
    } else if (recurrence == 'Yearly') {
      matchComponent = DateTimeComponents
          .dateAndTime; // Actually this repeats every year same date/time
      while (tzScheduledDate.isBefore(now)) {
        tzScheduledDate = tz.TZDateTime(
          tz.local,
          tzScheduledDate.year + 1,
          tzScheduledDate.month,
          tzScheduledDate.day,
          tzScheduledDate.hour,
          tzScheduledDate.minute,
        );
      }
    } else {
      // None/Once: Ensure future
      if (tzScheduledDate.isBefore(now)) {
        // If it's 5 seconds ago, maybe schedule for 5 seconds from now?
        // Or just fail. Let's strictly use the user's date.
      }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Channel for Reminder Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponent,
    );
  }

  tz.TZDateTime _nextInstanceOfDay(int day, tz.TZDateTime scheduledTime) {
    tz.TZDateTime scheduledDate = scheduledTime;
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    // Ensure it's in the future
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
