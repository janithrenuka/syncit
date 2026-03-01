import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reminder.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Reminder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime time;

  @HiveField(3)
  bool isTaken;

  @HiveField(4)
  final String recurrence; // 'None' (Once), 'Daily', 'Weekly', 'Monthly', 'Yearly'

  @HiveField(5)
  final List<int>? weekdays; // 1=Mon, 7=Sun

  @HiveField(6)
  final DateTime? startDate;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.isTaken = false,
    this.recurrence = 'None',
    this.weekdays,
    this.startDate,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderToJson(this);
}
