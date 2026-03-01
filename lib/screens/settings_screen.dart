import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/services/auth_service.dart';
import 'package:syncit/services/backup_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: user != null
                ? GoogleUserCircleAvatar(identity: user)
                : const Icon(Icons.account_circle, size: 40),
            title: Text(
              user != null
                  ? user.displayName ?? 'Google User'
                  : 'Not Signed In',
            ),
            subtitle: Text(
              user != null ? user.email : 'Sign in to backup data',
            ),
            trailing: user != null
                ? TextButton(
                    onPressed: authService.signOut,
                    child: const Text('Sign Out'),
                  )
                : FilledButton(
                    onPressed: authService.signIn,
                    child: const Text('Sign In'),
                  ),
          ),

          const Divider(),
          _buildSectionHeader(context, 'Backup & Restore'),

          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Backup to Drive'),
              subtitle: const Text('Save your reminders to Google Drive'),
              onTap: () async {
                try {
                  await context.read<BackupService>().uploadToDrive();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup successful!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Backup failed: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Restore from Drive'),
              subtitle: const Text('Overwrite local data with Drive backup'),
              onTap: () async {
                try {
                  await context.read<BackupService>().restoreFromDrive();
                  // Ideally show confirmation dialog before restoring as it overwrites
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restore successful!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restore failed: $e')),
                    );
                  }
                }
              },
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Sign in with Google to enable Cloud Backup.'),
            ),
          ],

          const Divider(),
          _buildSectionHeader(context, 'Local Export'),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Export to Storage'),
            subtitle: const Text('Save JSON file to Downloads/Documents'),
            onTap: () async {
              try {
                final path = await context
                    .read<BackupService>()
                    .createLocalBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Exported to $path')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
