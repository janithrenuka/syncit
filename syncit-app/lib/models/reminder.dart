import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 0)
class Reminder extends HiveObject {
  @HiveField(0)
  String topic;

  @HiveField(1)
  String subtopic;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime time;

  @HiveField(5)
  bool isRecurring;

  @HiveField(6)
  String? recurrenceType; // Daily, Weekly, Monthly, Yearly

  Reminder({
    required this.topic,
    required this.subtopic,
    required this.description,
    required this.date,
    required this.time,
    required this.isRecurring,
    this.recurrenceType,
  });

  DateTime get nextOccurrence {
    final now = DateTime.now();
    DateTime scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (!isRecurring) return scheduled;

    // If it's already in the future, return it
    if (scheduled.isAfter(now)) return scheduled;

    // Otherwise, calculate the next one
    while (!scheduled.isAfter(now)) {
      final type = recurrenceType ?? 'Daily';
      switch (type) {
        case 'Daily':
          scheduled = scheduled.add(const Duration(days: 1));
          break;
        case 'Weekly':
          scheduled = scheduled.add(const Duration(days: 7));
          break;
        case 'Monthly':
          scheduled = DateTime(
            scheduled.year,
            scheduled.month + 1,
            scheduled.day,
            scheduled.hour,
            scheduled.minute,
          );
          break;
        case 'Yearly':
          scheduled = DateTime(
            scheduled.year + 1,
            scheduled.month,
            scheduled.day,
            scheduled.hour,
            scheduled.minute,
          );
          break;
        default:
          return scheduled;
      }
    }
    return scheduled;
  }

  /// Updates the base [date] and [time] to the [nextOccurrence] if it has passed.
  Future<void> rollForwardToNextOccurrence() async {
    if (!isRecurring) return;

    final nextOcc = nextOccurrence;
    final nextOccDateOnly = DateTime(nextOcc.year, nextOcc.month, nextOcc.day);

    // If the next occurrence is after our stored date, roll forward
    if (nextOccDateOnly.isAfter(date)) {
      date = nextOccDateOnly;
      // Also update the time field to keep its date components in sync
      time = nextOcc;

      // Heal data: if type was missing, set it to the default 'Daily'
      recurrenceType ??= 'Daily';

      if (isInBox) {
        await save();
      }
    }
  }
}
