import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncit/models/note.dart';

class NoteService {
  final String _boxName = 'notesBox';

  Future<Box<Note>> get _box async => await Hive.openBox<Note>(_boxName);

  // Create
  Future<void> addNote(Note note) async {
    var box = await _box;
    await box.add(note);
  }

  // Read
  Future<List<Note>> getAllNotes() async {
    var box = await _box;
    return box.values.toList();
  }

  // Update
  Future<void> updateNote(int index, Note note) async {
    var box = await _box;
    await box.putAt(index, note);
  }

  // Delete
  Future<void> deleteNote(int index) async {
    var box = await _box;
    await box.deleteAt(index);
  }
}
