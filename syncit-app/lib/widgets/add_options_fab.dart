import 'package:flutter/material.dart';
import 'package:syncit/screens/add_reminder_screen.dart';
import 'package:syncit/screens/add_todo_screen.dart';
import 'package:syncit/screens/add_checklist_screen.dart';
import 'package:syncit/screens/add_note_screen.dart';

class AddOptionsFab extends StatefulWidget {
  final VoidCallback? onRefresh;

  const AddOptionsFab({super.key, this.onRefresh});

  @override
  State<AddOptionsFab> createState() => _AddOptionsFabState();
}

class _AddOptionsFabState extends State<AddOptionsFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showMenu() async {
    if (_isExpanded) return;

    setState(() {
      _isExpanded = true;
      _controller.forward();
    });

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: curvedAnimation,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTile(
                      context,
                      'Add Reminder',
                      Icons.notifications_active,
                      Colors.blue,
                      const AddReminderScreen(),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      'Add Todo',
                      Icons.check_box,
                      Colors.green,
                      const AddTodoScreen(),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      'Add Checklist',
                      Icons.checklist,
                      Colors.orange,
                      const AddChecklistScreen(),
                    ),
                    const SizedBox(height: 12),
                    _buildTile(
                      context,
                      'Add Note',
                      Icons.note_alt,
                      Colors.purple,
                      const AddNoteScreen(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget destination,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(240),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _showMenu,
      backgroundColor: Colors.white,
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      child: RotationTransition(
        turns: _rotateAnimation,
        child: const Icon(Icons.add, size: 36.0, color: Colors.black87),
      ),
    );
  }
}
