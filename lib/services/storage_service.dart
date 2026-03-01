import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/models/log.dart';

class StorageService {
  static const String _reminderBoxName = 'reminders';
  static const String _logBoxName = 'logs';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ReminderAdapter());
    Hive.registerAdapter(LogAdapter());
    await Hive.openBox<Reminder>(_reminderBoxName);
    await Hive.openBox<Log>(_logBoxName);
  }

  Box<Reminder> get _reminderBox => Hive.box<Reminder>(_reminderBoxName);
  Box<Log> get _logBox => Hive.box<Log>(_logBoxName);

  // --- Reminders ---

  List<Reminder> getAllReminders() {
    return _reminderBox.values.toList();
  }

  Future<void> addReminder(Reminder reminder) async {
    await _reminderBox.put(reminder.id, reminder);
  }

  Future<void> updateReminder(Reminder reminder) async {
    await reminder.save();
  }

  Future<void> deleteReminder(String id) async {
    await _reminderBox.delete(id);
    // Optional: Delete logs associated with this reminder
    final logsToDelete = _logBox.values.where((log) => log.reminderId == id).toList();
    for (var log in logsToDelete) {
      await log.delete();
    }
  }

  // --- Logs ---

  List<Log> getAllLogs() {
    return _logBox.values.toList();
  }

  List<Log> getLogsForReminder(String reminderId) {
    return _logBox.values.where((log) => log.reminderId == reminderId).toList();
  }

  bool isReminderCompletedOnDate(String reminderId, DateTime date) {
    return _logBox.values.any((log) => 
      log.reminderId == reminderId && 
      log.date.year == date.year && 
      log.date.month == date.month && 
      log.date.day == date.day
    );
  }

  Log? getLogForDate(String reminderId, DateTime date) {
    try {
      return _logBox.values.firstWhere((log) => 
        log.reminderId == reminderId && 
        log.date.year == date.year && 
        log.date.month == date.month && 
        log.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> logCompletion(String reminderId, DateTime date) async {
    // Check if already logged to avoid duplicates
    if (isReminderCompletedOnDate(reminderId, date)) return;

    final log = Log(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID
      reminderId: reminderId,
      date: DateTime(date.year, date.month, date.day),
      completedAt: DateTime.now(),
    );
    await _logBox.put(log.id, log);
  }

  Future<void> removeLog(String reminderId, DateTime date) async {
    final logToDelete = _logBox.values.firstWhere(
      (log) => 
        log.reminderId == reminderId && 
        log.date.year == date.year && 
        log.date.month == date.month && 
        log.date.day == date.day,
      orElse: () => Log(id: '', reminderId: '', date: DateTime.now(), completedAt: DateTime.now()), // Dummy
    );
    
    if (logToDelete.id.isNotEmpty) {
      await logToDelete.delete();
    }
  }

  // For Backup purpose
  List<Map<String, dynamic>> exportToJson() {
    return [
      ..._reminderBox.values.map((e) => {'type': 'reminder', ...e.toJson()}),
      ..._logBox.values.map((e) => {'type': 'log', ...e.toJson()}),
    ];
  }
  
  Future<void> importFromJson(List<dynamic> jsonList) async {
    await _reminderBox.clear();
    await _logBox.clear();
    
    for (var item in jsonList) {
      if (item['type'] == 'reminder') {
        item.remove('type');
        final reminder = Reminder.fromJson(item);
        await _reminderBox.put(reminder.id, reminder);
      } else if (item['type'] == 'log') {
        item.remove('type');
        final log = Log.fromJson(item);
        await _logBox.put(log.id, log);
      }
      // Backwards compatibility for old format (list of reminders only)
      else if (item['id'] != null && item['title'] != null) {
         final reminder = Reminder.fromJson(item);
         await _reminderBox.put(reminder.id, reminder);
      }
    }
  }
}
