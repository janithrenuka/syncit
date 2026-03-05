import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/services/notification_service.dart';
import 'package:syncit/services/reminder_service.dart';
import 'package:animate_do/animate_do.dart';

class ReminderAlertScreen extends StatefulWidget {
  final Reminder reminder;

  const ReminderAlertScreen({super.key, required this.reminder});

  @override
  State<ReminderAlertScreen> createState() => _ReminderAlertScreenState();
}

class _ReminderAlertScreenState extends State<ReminderAlertScreen> {
  @override
  void initState() {
    super.initState();
    _startAlert();
  }

  Future<void> _startAlert() async {
    // Standard vibration for reminders (not continuous like alarm)
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }
  }

  void _markDone() async {
    Vibration.cancel();

    await ReminderService().completeReminder(widget.reminder);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _snooze() async {
    Vibration.cancel();

    // Snooze for 5 minutes
    final nextTime = DateTime.now().add(const Duration(minutes: 5));

    final notificationService = NotificationService();
    // Schedule a one-time notification for snooze
    await notificationService.handleReminder(
      widget.reminder.key + 20000, // Offset to avoid collision
      Reminder(
        topic: '${widget.reminder.topic} (Snooze)',
        subtopic: widget.reminder.subtopic,
        description: widget.reminder.description,
        date: nextTime,
        time: nextTime,
        isRecurring: false,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Pulse(
                  child: Text(
                    widget.reminder.topic,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.reminder.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FadeInUp(
                    child: Text(
                      widget.reminder.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 80),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElasticInLeft(
                        child: _AlertActionButton(
                          label: 'SNOOZE',
                          icon: Icons.snooze,
                          color: Colors.white24,
                          onPressed: _snooze,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElasticInRight(
                        child: _AlertActionButton(
                          label: 'DONE',
                          icon: Icons.check_circle,
                          color: Colors.white,
                          textColor: Colors.blue.shade900,
                          onPressed: _markDone,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _AlertActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
