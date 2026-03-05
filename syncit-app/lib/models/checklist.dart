import 'package:hive/hive.dart';

part 'checklist.g.dart';

@HiveType(typeId: 2)
class Checklist extends HiveObject {
  @HiveField(0)
  String topic;

  @HiveField(1)
  List<ChecklistItem> itemList;

  Checklist({required this.topic, required this.itemList});
}

@HiveType(typeId: 3)
class ChecklistItem extends HiveObject {
  @HiveField(0)
  String text;

  @HiveField(1)
  bool isChecked;

  ChecklistItem({required this.text, this.isChecked = false});
}
