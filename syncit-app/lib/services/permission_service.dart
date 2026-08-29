import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check and request all necessary permissions with explanations
  Future<void> checkAndRequestPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('permissions_onboarded') ?? false;

    if (!isFirstLaunch) {
      // 1. Notifications (Essential for reminders)
      if (!await Permission.notification.isGranted) {
        if (!context.mounted) return;
        await _showExplanation(
          context,
          title: 'Notifications',
          message:
              'SyncIt needs notification permission to alert you about your scheduled reminders.',
          icon: Icons.notifications_active,
          onConfirm: () => Permission.notification.request(),
        );
      }

      // Note: Storage permissions are handled contextually by FilePicker for backup/restore.
      // No global storage permission needed.

      await prefs.setBool('permissions_onboarded', true);
    }
  }

  Future<void> _showExplanation(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LATER'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm();
            },
            child: const Text('ALLOW'),
          ),
        ],
      ),
    );
  }
}
