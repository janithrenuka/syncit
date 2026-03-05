import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/services/notification_service.dart';

class ReminderService {
  final String _boxName = 'remindersBox';

  Future<Box<Reminder>> get _box async =>
      await Hive.openBox<Reminder>(_boxName);

  // Create
  Future<void> addReminder(Reminder reminder) async {
    var box = await _box;
    final key = await box.add(reminder);
    await NotificationService().handleReminder(key, reminder);
  }

  // Read
  Future<List<Reminder>> getAllReminders() async {
    await cleanupPastReminders();
    var box = await _box;
    return box.values.toList();
  }

  // Update
  Future<void> updateReminder(Reminder reminder) async {
    final key = reminder.key as int;
    await reminder.save();
    await NotificationService().handleReminder(key, reminder);
  }

  // Delete
  Future<void> deleteReminder(Reminder reminder) async {
    final key = reminder.key as int;
    await reminder.delete();
    await NotificationService().cancelNotification(key + 10000);
  }

  // Complete (Delete or Reschedule)
  Future<void> completeReminder(Reminder reminder) async {
    if (reminder.isRecurring) {
      // Roll forward to next occurrence
      await reminder.rollForwardToNextOccurrence();
      if (reminder.key != null) {
        await NotificationService().handleReminder(
          reminder.key as int,
          reminder,
        );
      }
    } else {
      // Delete one-time reminder
      await deleteReminder(reminder);
    }
  }

  // Cleanup
  Future<void> cleanupPastReminders() async {
    var box = await _box;
    final now = DateTime.now();
    final keysToDelete = <dynamic>[];

    for (var i = 0; i < box.length; i++) {
      final reminder = box.getAt(i);
      if (reminder != null) {
        if (!reminder.isRecurring) {
          final reminderDateTime = DateTime(
            reminder.date.year,
            reminder.date.month,
            reminder.date.day,
            reminder.time.hour,
            reminder.time.minute,
          );
          if (reminderDateTime.isBefore(now)) {
            keysToDelete.add(box.keyAt(i));
          }
        } else {
          // Recurring reminder maintenance
          await reminder.rollForwardToNextOccurrence();
        }
      }
    }

    for (var key in keysToDelete) {
      await box.delete(key);
      await NotificationService().cancelNotification((key as int) + 10000);
    }
  }
}
