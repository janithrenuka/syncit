import 'package:flutter/material.dart';
import 'package:syncit/models/checklist.dart';
import 'package:syncit/services/checklist_service.dart';

class AddChecklistScreen extends StatefulWidget {
  final Checklist? existingChecklist;
  final int? index;

  const AddChecklistScreen({super.key, this.existingChecklist, this.index});

  @override
  State<AddChecklistScreen> createState() => _AddChecklistScreenState();
}

class _AddChecklistScreenState extends State<AddChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();

  // Dynamic list of controllers for checklist items
  final List<TextEditingController> _itemControllers = [
    TextEditingController(),
  ];
  final List<bool> _itemCheckedStates = [false];

  @override
  void initState() {
    super.initState();
    if (widget.existingChecklist != null) {
      _topicController.text = widget.existingChecklist!.topic;
      if (widget.existingChecklist!.itemList.isNotEmpty) {
        _itemControllers.clear();
        _itemCheckedStates.clear();
        for (var item in widget.existingChecklist!.itemList) {
          _itemControllers.add(TextEditingController(text: item.text));
          _itemCheckedStates.add(item.isChecked);
        }
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _itemCheckedStates.add(false);
    });
  }

  void _removeItemField(int index) {
    if (_itemControllers.length > 1) {
      setState(() {
        _itemControllers[index].dispose();
        _itemControllers.removeAt(index);
        _itemCheckedStates.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Filter out empty items
      final validItems = _itemControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (validItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item.')),
        );
        return;
      }

      final List<ChecklistItem> checklistItems = [];
      for (int i = 0; i < _itemControllers.length; i++) {
        final text = _itemControllers[i].text.trim();
        if (text.isNotEmpty) {
          checklistItems.add(
            ChecklistItem(text: text)..isChecked = _itemCheckedStates[i],
          );
        }
      }

      final checklist = Checklist(
        topic: _topicController.text.trim(),
        itemList: checklistItems,
      );

      final checklistService = ChecklistService();
      if (widget.index != null) {
        await checklistService.updateChecklist(widget.index!, checklist);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checklist Updated Successfully!')),
          );
        }
      } else {
        await checklistService.addChecklist(checklist);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checklist Added Successfully!')),
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
    const primaryColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingChecklist != null ? 'Edit Checklist' : 'Add Checklist',
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
                      labelText: 'Checklist Topic',
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

                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Checklist Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItemField,
                        icon: const Icon(Icons.add, color: primaryColor),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _itemControllers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _itemControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Item ${index + 1}',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(
                                  Icons.check_box_outline_blank,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          if (_itemControllers.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeItemField(index),
                              icon: const Icon(Icons.remove_circle),
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
                    widget.existingChecklist != null
                        ? 'Update Checklist'
                        : 'Save Checklist',
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
