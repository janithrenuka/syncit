import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/models/checklist.dart';
import 'package:syncit/services/reminder_service.dart';
import 'package:syncit/services/checklist_service.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  List<Reminder> _todayReminders = [];
  List<Checklist> _activeChecklists = [];

  int _totalChecklistItems = 0;
  int _completedChecklistItems = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();

    // Reminders (Lookahead 7 days)
    final allReminders = await ReminderService().getAllReminders();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    _todayReminders = allReminders.where((r) {
      final nextOcc = r.nextOccurrence;
      final nextOccDate = DateTime(nextOcc.year, nextOcc.month, nextOcc.day);
      final todayDate = DateTime(now.year, now.month, now.day);

      return !nextOccDate.isBefore(todayDate) &&
          !nextOccDate.isAfter(
            DateTime(
              sevenDaysFromNow.year,
              sevenDaysFromNow.month,
              sevenDaysFromNow.day,
            ),
          );
    }).toList();

    // Initial sort
    _todayReminders.sort((a, b) {
      return a.nextOccurrence.compareTo(b.nextOccurrence);
    });

    // Checklists
    final allChecklists = await ChecklistService().getAllChecklists();
    _activeChecklists = [];
    _totalChecklistItems = 0;
    _completedChecklistItems = 0;

    for (var c in allChecklists) {
      final total = c.itemList.length;
      final completed = c.itemList.where((item) => item.isChecked).length;
      _totalChecklistItems += total;
      _completedChecklistItems += completed;

      if (completed < total) {
        _activeChecklists.add(c);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String todayDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    double progress = _totalChecklistItems == 0
        ? 0
        : _completedChecklistItems / _totalChecklistItems;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            todayDate,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Today's Overview",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Overview Card
          _buildProgressCard(progress),

          const SizedBox(height: 32),

          // Timeline
          const Text(
            "Up Next",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildUpcomingTimeline(),

          const SizedBox(height: 32),

          // Active Checklists
          const Text(
            "Active Checklists",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActiveChecklists(),

          const SizedBox(height: 80), // padding for FAB
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.greenAccent,
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Checklist Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$_completedChecklistItems of $_totalChecklistItems tasks completed",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTimeline() {
    final now = DateTime.now();
    if (_todayReminders.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade100,
        elevation: 0,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              "Nothing scheduled for today!",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    // Sort reminders by their next occurrence
    final List<Reminder> upcoming = [..._todayReminders];
    upcoming.sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));

    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: upcoming.map((reminder) {
        final DateTime nextOcc = reminder.nextOccurrence;
        final DateTime itemDate = DateTime(
          nextOcc.year,
          nextOcc.month,
          nextOcc.day,
        );

        String dateLabel = "";
        if (itemDate.isAtSameMomentAs(today)) {
          dateLabel = "Today";
        } else if (itemDate.isAtSameMomentAs(
          today.add(const Duration(days: 1)),
        )) {
          dateLabel = "Tomorrow";
        } else if (itemDate.isAfter(today)) {
          dateLabel = DateFormat('MMM d').format(itemDate);
        }

        return _buildTimelineItem(
          time: DateFormat('h:mm a').format(reminder.nextOccurrence),
          dateLabel: dateLabel,
          title: reminder.topic,
          subtitle: reminder.isRecurring
              ? "Recurring: ${reminder.recurrenceType}"
              : "Reminder",
          icon: Icons.notifications,
          color: Colors.blue,
          onTap: () => widget.onNavigate(1),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String dateLabel,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (dateLabel.isNotEmpty && dateLabel != "Today")
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 2,
              height: 50,
              color: color.withAlpha(50),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChecklists() {
    if (_activeChecklists.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade100,
        elevation: 0,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              "No active checklists!",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _activeChecklists.map((checklist) {
        final total = checklist.itemList.length;
        final completed = checklist.itemList
            .where((item) => item.isChecked)
            .length;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => widget.onNavigate(3),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.checklist, color: Colors.orange),
              title: Text(
                checklist.topic,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : completed / total,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.orange,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
