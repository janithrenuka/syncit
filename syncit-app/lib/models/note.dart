import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 4)
class Note extends HiveObject {
  @HiveField(0)
  String topic;

  @HiveField(1)
  String description;

  @HiveField(2)
  List<String> attachmentList;

  Note({
    required this.topic,
    required this.description,
    required this.attachmentList,
  });
}
