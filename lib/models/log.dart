import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'log.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Log extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String reminderId;

  @HiveField(2)
  final DateTime date; // The date this was completed (ignoring time usually)

  @HiveField(3)
  final DateTime completedAt; // Exact timestamp

  Log({
    required this.id,
    required this.reminderId,
    required this.date,
    required this.completedAt,
  });

  factory Log.fromJson(Map<String, dynamic> json) => _$LogFromJson(json);
  Map<String, dynamic> toJson() => _$LogToJson(this);
}
