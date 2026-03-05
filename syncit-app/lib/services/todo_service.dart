import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncit/models/todo.dart';

class TodoService {
  final String _boxName = 'todosBox';

  Future<Box<Todo>> get _box async => await Hive.openBox<Todo>(_boxName);

  // Create
  Future<void> addTodo(Todo todo) async {
    var box = await _box;
    await box.add(todo);
  }

  // Read
  Future<List<Todo>> getAllTodos() async {
    var box = await _box;
    return box.values.toList();
  }

  // Update
  Future<void> updateTodo(int index, Todo todo) async {
    var box = await _box;
    await box.putAt(index, todo);
  }

  // Delete
  Future<void> deleteTodo(int index) async {
    var box = await _box;
    await box.deleteAt(index);
  }
}
