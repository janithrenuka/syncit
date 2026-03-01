// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 0;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      title: fields[1] as String,
      time: fields[2] as DateTime,
      isTaken: fields[3] as bool,
      recurrence: fields[4] as String,
      weekdays: (fields[5] as List?)?.cast<int>(),
      startDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.isTaken)
      ..writeByte(4)
      ..write(obj.recurrence)
      ..writeByte(5)
      ..write(obj.weekdays)
      ..writeByte(6)
      ..write(obj.startDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reminder _$ReminderFromJson(Map<String, dynamic> json) => Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      time: DateTime.parse(json['time'] as String),
      isTaken: json['isTaken'] as bool? ?? false,
      recurrence: json['recurrence'] as String? ?? 'None',
      weekdays: (json['weekdays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
    );

Map<String, dynamic> _$ReminderToJson(Reminder instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'time': instance.time.toIso8601String(),
      'isTaken': instance.isTaken,
      'recurrence': instance.recurrence,
      'weekdays': instance.weekdays,
      'startDate': instance.startDate?.toIso8601String(),
    };
