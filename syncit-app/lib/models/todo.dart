import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 1)
class Todo extends HiveObject {
  @HiveField(0)
  String topic;

  @HiveField(1)
  List<String> subTodoList;

  Todo({required this.topic, required this.subTodoList});
}
