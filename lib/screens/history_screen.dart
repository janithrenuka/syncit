import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/services/storage_service.dart';
import 'package:syncit/models/log.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          final logs = storage.getAllLogs();
          // Sort by date descending
          logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));

          if (logs.isEmpty) {
             return const Center(child: Text("No history yet"));
          }

          final remindersMap = {for (var r in storage.getAllReminders()) r.id: r};

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final reminder = remindersMap[log.reminderId];
              final title = reminder?.title ?? 'Unknown Reminder';

              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(title),
                subtitle: Text("Completed: ${DateFormat('MMM d, y • hh:mm a').format(log.completedAt)}"),
              );
            },
          );
        },
      ),
    ); 
  }
}
