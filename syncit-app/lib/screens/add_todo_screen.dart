import 'package:flutter/material.dart';
import 'package:syncit/models/todo.dart';
import 'package:syncit/services/todo_service.dart';

class AddTodoScreen extends StatefulWidget {
  final Todo? existingTodo;
  final int? index;

  const AddTodoScreen({super.key, this.existingTodo, this.index});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();

  // Dynamic list of controllers for sub-todos
  final List<TextEditingController> _subTodoControllers = [
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTodo != null) {
      _topicController.text = widget.existingTodo!.topic;
      if (widget.existingTodo!.subTodoList.isNotEmpty) {
        _subTodoControllers.clear();
        for (var sub in widget.existingTodo!.subTodoList) {
          _subTodoControllers.add(TextEditingController(text: sub));
        }
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    for (var controller in _subTodoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubTodoField() {
    setState(() {
      _subTodoControllers.add(TextEditingController());
    });
  }

  void _removeSubTodoField(int index) {
    if (_subTodoControllers.length > 1) {
      setState(() {
        _subTodoControllers[index].dispose();
        _subTodoControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Filter out empty sub-todos
      final validSubTodos = _subTodoControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (validSubTodos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one sub-todo.')),
        );
        return;
      }

      final todo = Todo(
        topic: _topicController.text.trim(),
        subTodoList: validSubTodos,
      );

      final todoService = TodoService();
      if (widget.index != null) {
        await todoService.updateTodo(widget.index!, todo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos Updated Successfully!')),
          );
        }
      } else {
        await todoService.addTodo(todo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos Added Successfully!')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTodo != null ? 'Edit Todo' : 'Add Todo',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Topic Field
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Todo Topic',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.topic, color: primaryColor),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a topic';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Sub-Todos Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sub Todos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSubTodoField,
                        icon: const Icon(Icons.add, color: primaryColor),
                        label: const Text(
                          'Add More',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Sub-Todos List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subTodoControllers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _subTodoControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Todo ${index + 1}',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(
                                  Icons.check_box_outline_blank,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          if (_subTodoControllers.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeSubTodoField(index),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red.shade400,
                              tooltip: 'Remove',
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Fixed Submit Button at Bottom
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.existingTodo != null ? 'Update Todos' : 'Save Todos',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 54),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
