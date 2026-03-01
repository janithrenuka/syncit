import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/services/storage_service.dart';
import 'package:syncit/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  // Scheduling State
  bool _isRecurring = false; // false = Once, true = Repeat
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate =
      DateTime.now(); // Used for 'Once' date or 'Start Date'
  String _recurrence = 'Daily'; // Default for repeat
  List<int> _selectedWeekdays = []; // 1=Mon, 7=Sun

  final List<String> _recurrenceOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        _selectedWeekdays.remove(day);
      } else {
        _selectedWeekdays.add(day);
      }
    });
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring &&
          _recurrence == 'Weekly' &&
          _selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one day for weekly limits'),
          ),
        );
        return;
      }

      // Combine Date and Time
      // For 'Once': This is the exact trigger time.
      // For 'Repeat': This serves as the 'Start Date' + 'Time of day'.
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // If 'Once' and time is in past, warn or adjust? For now allow, notification svc handles immediate.

      final reminder = Reminder(
        id: const Uuid().v4(),
        title: _titleController.text,
        time: scheduledDateTime,
        recurrence: _isRecurring ? _recurrence : 'None',
        startDate: _isRecurring ? scheduledDateTime : null,
        weekdays: (_isRecurring && _recurrence == 'Weekly')
            ? _selectedWeekdays
            : null,
      );

      context.read<StorageService>().addReminder(reminder);

      context.read<NotificationService>().scheduleNotification(
        id: reminder.id.hashCode,
        title: "Time for ${reminder.title}",
        body: "Don't forget your medication!",
        scheduledTime: scheduledDateTime,
        recurrence: reminder.recurrence,
        weekdays: reminder.weekdays,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: 20),

                // Radio Buttons: Once vs Repeat
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Once'),
                        value: false,
                        groupValue: _isRecurring,
                        onChanged: (val) => setState(() => _isRecurring = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Repeat'),
                        value: true,
                        groupValue: _isRecurring,
                        onChanged: (val) => setState(() => _isRecurring = val!),
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Common: Time Picker
                ListTile(
                  title: Text("Time: ${_selectedTime.format(context)}"),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),

                // Date Picker (Label changes based on mode)
                ListTile(
                  title: Text(
                    "${_isRecurring ? 'Start Date' : 'Date'}: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 20),

                // Recurring Options
                if (_isRecurring) ...[
                  DropdownButtonFormField<String>(
                    value: _recurrence,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: _recurrenceOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _recurrence = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Weekday Selector (Only for Weekly)
                  if (_recurrence == 'Weekly') ...[
                    const Text(
                      "Select Days:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: List.generate(7, (index) {
                        final day = index + 1; // 1 = Mon
                        final isSelected = _selectedWeekdays.contains(day);
                        final dayName = [
                          'M',
                          'T',
                          'W',
                          'T',
                          'F',
                          'S',
                          'S',
                        ][index];
                        return FilterChip(
                          label: Text(dayName),
                          selected: isSelected,
                          onSelected: (_) => _toggleWeekday(day),
                        );
                      }),
                    ),
                  ],
                ],

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _saveReminder,
                    child: const Text('Save Reminder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
