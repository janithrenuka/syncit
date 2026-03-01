// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogAdapter extends TypeAdapter<Log> {
  @override
  final int typeId = 1;

  @override
  Log read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Log(
      id: fields[0] as String,
      reminderId: fields[1] as String,
      date: fields[2] as DateTime,
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Log obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reminderId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Log _$LogFromJson(Map<String, dynamic> json) => Log(
      id: json['id'] as String,
      reminderId: json['reminderId'] as String,
      date: DateTime.parse(json['date'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$LogToJson(Log instance) => <String, dynamic>{
      'id': instance.id,
      'reminderId': instance.reminderId,
      'date': instance.date.toIso8601String(),
      'completedAt': instance.completedAt.toIso8601String(),
    };
