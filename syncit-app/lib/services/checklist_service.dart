import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncit/models/checklist.dart';

class ChecklistService {
  final String _boxName = 'checklistsBox';

  Future<Box<Checklist>> get _box async =>
      await Hive.openBox<Checklist>(_boxName);

  // Create
  Future<void> addChecklist(Checklist checklist) async {
    var box = await _box;
    await box.add(checklist);
  }

  // Read
  Future<List<Checklist>> getAllChecklists() async {
    var box = await _box;
    return box.values.toList();
  }

  // Update
  Future<void> updateChecklist(int index, Checklist checklist) async {
    var box = await _box;
    await box.putAt(index, checklist);
  }

  // Delete
  Future<void> deleteChecklist(int index) async {
    var box = await _box;
    await box.deleteAt(index);
  }
}
