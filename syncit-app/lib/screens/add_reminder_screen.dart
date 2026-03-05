import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/services/reminder_service.dart';
import 'dart:developer' as developer;

class AddReminderScreen extends StatefulWidget {
  final Reminder? existingReminder;

  const AddReminderScreen({super.key, this.existingReminder});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _subTopicController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;
  String _recurrenceOption = 'Daily';

  final List<String> _recurrenceOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      final r = widget.existingReminder!;
      _topicController.text = r.topic;
      _subTopicController.text = r.subtopic;
      _descriptionController.text = r.description;
      _selectedDate = r.date;
      _selectedTime = TimeOfDay(hour: r.time.hour, minute: r.time.minute);
      _isRecurring = r.isRecurring;
      _recurrenceOption = r.recurrenceType ?? 'Daily';
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _subTopicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both Date and Time')),
        );
        return;
      }

      final reminderTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (reminderTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot set a reminder in the past!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final reminder = Reminder(
        topic: _topicController.text.trim(),
        subtopic: _subTopicController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate!,
        time: reminderTime,
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceOption : null,
      );

      final reminderService = ReminderService();

      try {
        if (widget.existingReminder != null) {
          final updatedReminder = widget.existingReminder!;
          updatedReminder.topic = reminder.topic;
          updatedReminder.subtopic = reminder.subtopic;
          updatedReminder.description = reminder.description;
          updatedReminder.date = reminder.date;
          updatedReminder.time = reminder.time;
          updatedReminder.isRecurring = reminder.isRecurring;
          updatedReminder.recurrenceType = reminder.recurrenceType;

          await reminderService.updateReminder(updatedReminder);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder Updated Successfully!')),
            );
          }
        } else {
          await reminderService.addReminder(reminder);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder Added Successfully!')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        developer.log('Error submitting reminder: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingReminder != null ? 'Edit Reminder' : 'Add Reminder',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: primaryColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subTopicController,
                decoration: const InputDecoration(
                  labelText: 'Sub Topic (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: primaryColor),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: primaryColor,
                          ),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat(
                                  'MMM d, yyyy',
                                ).format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey.shade600
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.access_time,
                            color: primaryColor,
                          ),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                          style: TextStyle(
                            color: _selectedTime == null
                                ? Colors.grey.shade600
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recurring Toggle
              SwitchListTile(
                title: const Text('Is Recurring?'),
                subtitle: const Text('Repeat this reminder'),
                value: _isRecurring,
                activeTrackColor: primaryColor.withAlpha(100),
                activeThumbColor: primaryColor,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                secondary: const Icon(Icons.repeat, color: primaryColor),
                contentPadding: EdgeInsets.zero,
              ),

              // Recurring Dropdown (Visible only if toggle is ON)
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _recurrenceOption,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_repeat, color: primaryColor),
                  ),
                  items: _recurrenceOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue != null) {
                        _recurrenceOption = newValue;
                      }
                    });
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Submit Button
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.existingReminder != null
                      ? 'Update Reminder'
                      : 'Submit Reminder',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
