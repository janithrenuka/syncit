import 'package:flutter/material.dart';
import 'package:syncit/models/checklist.dart';
import 'package:syncit/services/checklist_service.dart';
import 'package:syncit/screens/add_checklist_screen.dart';

class ChecklistsScreen extends StatefulWidget {
  const ChecklistsScreen({super.key});

  @override
  State<ChecklistsScreen> createState() => _ChecklistsScreenState();
}

class _ChecklistsScreenState extends State<ChecklistsScreen> {
  final ChecklistService _checklistService = ChecklistService();
  List<Checklist> _checklists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklists();
  }

  Future<void> _loadChecklists() async {
    setState(() {
      _isLoading = true;
    });
    final checklists = await _checklistService.getAllChecklists();
    setState(() {
      _checklists = checklists;
      _isLoading = false;
    });
  }

  Future<void> _deleteChecklist(int index) async {
    await _checklistService.deleteChecklist(index);
    _loadChecklists(); // Refresh list after deletion
  }

  Future<void> _toggleChecklistItem(
    int listIndex,
    int itemIndex,
    bool? value,
  ) async {
    if (value == null) return;

    final checklist = _checklists[listIndex];
    checklist.itemList[itemIndex].isChecked = value;

    // Save to Hive
    await _checklistService.updateChecklist(listIndex, checklist);

    // Update UI directly since the object instance in _checklists is the same,
    // but we want to trigger a rebuild
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Checklists',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checklists.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _checklists.length,
              itemBuilder: (context, index) {
                final checklist = _checklists[index];
                return _buildChecklistCard(checklist, index, primaryColor);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, size: 80, color: Colors.orange.shade200),
          const SizedBox(height: 16),
          Text(
            'No checklists yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button on Home to add one',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(
    Checklist checklist,
    int listIndex,
    Color primaryColor,
  ) {
    int completedCount = checklist.itemList
        .where((item) => item.isChecked)
        .length;
    int totalCount = checklist.itemList.length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.playlist_add_check, color: primaryColor),
        ),
        title: Text(
          checklist.topic,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey.shade200,
                color: primaryColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$completedCount/$totalCount',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddChecklistScreen(
                      existingChecklist: checklist,
                      index: listIndex,
                    ),
                  ),
                );
                if (result == true) {
                  _loadChecklists();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(context, listIndex);
              },
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            color: Colors.grey.withAlpha(10),
            child: Column(
              children: List.generate(checklist.itemList.length, (itemIndex) {
                final item = checklist.itemList[itemIndex];
                return CheckboxListTile(
                  title: Text(
                    item.text,
                    style: TextStyle(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isChecked ? Colors.grey : Colors.black87,
                    ),
                  ),
                  value: item.isChecked,
                  activeColor: primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  onChanged: (value) =>
                      _toggleChecklistItem(listIndex, itemIndex, value),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Checklist'),
          content: const Text(
            'Are you sure you want to delete this checklist?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteChecklist(index);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checklist deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
