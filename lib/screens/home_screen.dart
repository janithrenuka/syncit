import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/services/storage_service.dart';
import 'package:syncit/screens/add_reminder_screen.dart';
import 'package:syncit/screens/settings_screen.dart';
import 'package:syncit/screens/history_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Today\'s Reminders',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          final allReminders = storage.getAllReminders();
          final today = DateTime.now();
          
          // Filter for today's reminders
          final todaysReminders = allReminders.where((reminder) {
            final date = reminder.time;
            if (reminder.recurrence == 'Daily') return true;
            if (reminder.recurrence == 'Monthly') return date.day == today.day;
            if (reminder.recurrence == 'Yearly') return date.day == today.day && date.month == today.month;
            // One-off
            return date.year == today.year && date.month == today.month && date.day == today.day;
          }).toList();

          if (todaysReminders.isEmpty) {
            return Center(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.check_circle_outline, size: 100, color: Theme.of(context).disabledColor),
                     const SizedBox(height: 20),
                     Text("All caught up!", style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            );
          }
          
          // Sort by time
          todaysReminders.sort((a, b) {
             final timeA = DateTime(today.year, today.month, today.day, a.time.hour, a.time.minute);
             final timeB = DateTime(today.year, today.month, today.day, b.time.hour, b.time.minute);
             return timeA.compareTo(timeB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todaysReminders.length,
            itemBuilder: (context, index) {
              final reminder = todaysReminders[index];
              final log = storage.getLogForDate(reminder.id, today);
              final isCompleted = log != null;
              
              Widget subtitleWidget;
              if (isCompleted) {
                 subtitleWidget = Text(
                   "Taken at ${DateFormat('hh:mm a').format(log.completedAt)}",
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                 );
              } else {
                 subtitleWidget = Text(
                    "${DateFormat('hh:mm a').format(reminder.time)} • ${reminder.recurrence}",
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  );
              }

              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: Card(
                  elevation: isCompleted ? 0 : 2,
                  color: isCompleted ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4) : null,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: isCompleted,
                      shape: const CircleBorder(),
                      onChanged: (value) async {
                        if (value == true) {
                          await storage.logCompletion(reminder.id, today);
                        } else {
                          await storage.removeLog(reminder.id, today);
                        }
                        setState(() {}); // Refresh UI
                      },
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subtitleWidget,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          storage.deleteReminder(reminder.id);
                          setState((){});
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReminderScreen()),
          );
        },
        label: const Text('New Reminder'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
