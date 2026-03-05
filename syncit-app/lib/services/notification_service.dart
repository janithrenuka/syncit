import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:syncit/models/reminder.dart';
import 'dart:developer' as developer;
import 'package:syncit/utils/navigator_key.dart';
import 'package:syncit/screens/reminder_alert_screen.dart';
import 'package:syncit/services/reminder_service.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) {
  // Handle background notification response here
  developer.log('Background Tapped: ${notificationResponse.actionId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize time zones
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // For iOS/macOS (if we expand later, permissions are needed)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            developer.log(
              'Foreground Tapped: ${notificationResponse.actionId}',
            );
            if (notificationResponse.actionId == 'dismiss_id' &&
                notificationResponse.id != null) {
              await flutterLocalNotificationsPlugin.cancel(
                id: notificationResponse.id!,
              );
            }

            if (notificationResponse.payload != null) {
              _handleNotificationPayload(notificationResponse.payload!);
            }
          },
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // We no longer handle cold start here to avoid race conditions with the Navigator.
    // Instead, handleAppLaunchNotification() should be called from the UI (e.g., HomeScreen).
  }

  Future<void> handleAppLaunchNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        _handleNotificationPayload(payload);
      }
    }
  }

  void _handleNotificationPayload(String payload) async {
    if (payload.startsWith('reminder_')) {
      final reminderKeyStr = payload.replaceFirst('reminder_', '');
      final reminderKey = int.tryParse(reminderKeyStr);
      if (reminderKey != null) {
        final reminderService = ReminderService();
        final reminders = await reminderService.getAllReminders();
        final reminder = reminders.cast<Reminder?>().firstWhere(
          (r) => r?.key == reminderKey,
          orElse: () => null,
        );

        if (reminder != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ReminderAlertScreen(reminder: reminder),
            ),
          );
        }
      }
    } else if (payload.startsWith('complete_reminder_') ||
        payload.startsWith('dismiss_reminder_')) {
      final isDismiss = payload.startsWith('dismiss_reminder_');
      final prefix = isDismiss ? 'dismiss_reminder_' : 'complete_reminder_';
      final reminderKeyStr = payload.replaceFirst(prefix, '');
      final reminderKey = int.tryParse(reminderKeyStr);
      if (reminderKey != null) {
        final reminderService = ReminderService();
        final reminders = await reminderService.getAllReminders();
        final reminder = reminders.cast<Reminder?>().firstWhere(
          (r) => r?.key == reminderKey,
          orElse: () => null,
        );

        if (reminder != null) {
          await reminderService.completeReminder(reminder);
          developer.log(
            'Reminder ${reminder.key} ${isDismiss ? 'dismissed' : 'completed'} via notification action',
          );
        }
      }
    }
  }

  // Request runtime permissions for Android 13+
  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Schedules or Cancels a Reminder based on whether it is in the future
  Future<void> handleReminder(int id, Reminder reminder) async {
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (scheduledDate.isBefore(now) && !reminder.isRecurring) {
      // Past reminder, just cancel/ignore
      await cancelNotification(id + 10000);
      return;
    }

    if (reminder.isRecurring) {
      DateTimeComponents? matchComponents;
      switch (reminder.recurrenceType) {
        case 'Daily':
          matchComponents = DateTimeComponents.time;
          break;
        case 'Weekly':
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
          break;
        case 'Monthly':
          matchComponents = DateTimeComponents.dayOfMonthAndTime;
          break;
        case 'Yearly':
          matchComponents = DateTimeComponents.dateAndTime;
          break;
      }

      await _scheduleRecurringNotification(
        id + 10000,
        reminder.topic,
        reminder.description,
        scheduledDate,
        matchComponents,
        reminder: reminder,
      );
    } else {
      await _scheduleExactNotification(
        id + 10000,
        reminder.topic,
        reminder.description,
        scheduledDate,
        reminder: reminder,
      );
    }
  }

  Future<void> _scheduleRecurringNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    DateTimeComponents? matchComponents, {
    Reminder? reminder,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'syncit_reminder_v1',
          'Reminders',
          channelDescription: 'Standard notifications for reminders',
          enableVibration: true,
          fullScreenIntent: false,
          additionalFlags: Int32List.fromList(<int>[4]),
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'complete_id',
              'Complete',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'dismiss_id',
              'Dismiss',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: reminder != null ? 'complete_reminder_${reminder.key}' : null,
    );
  }

  Future<void> _scheduleExactNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    Reminder? reminder,
  }) async {
    // Use system alerts as fallbacks for the initial notification
    // to ensure reliability if the full-screen intent is delayed.

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'syncit_reminder_v1',
          'Reminders',
          channelDescription: 'Standard notifications for reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: null,
          enableVibration: true,
          vibrationPattern: null,
          fullScreenIntent: false,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'complete_id',
              'Complete',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'dismiss_id',
              'Dismiss',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder != null ? 'complete_reminder_${reminder.key}' : null,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
