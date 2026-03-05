import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/providers/theme_provider.dart';
import 'package:syncit/services/backup_service.dart';
import 'package:syncit/screens/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    try {
      _showSnackBar('Creating backup bundle... Please wait.');
      final success = await _backupService.backupToLocal();

      if (success) {
        _showSnackBar('Backup bundle shared/saved successfully!');
      } else {
        _showSnackBar('Failed to create backup bundle or cancelled.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      _showSnackBar('Waiting for backup bundle selection...');
      final success = await _backupService.restoreFromLocal();

      if (success) {
        _showSnackBar('Restore successful! Restarting app state...');
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _showSnackBar(
          'Failed to restore. No backup selected or error occurred.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Theme Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ListTile(
                      leading: Icon(
                        themeProvider.themeMode == ThemeMode.light
                            ? Icons.light_mode
                            : themeProvider.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.settings_system_daydream,
                        color: Colors.amber,
                      ),
                      title: const Text('App Theme'),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeProvider.themeMode,
                        onChanged: (ThemeMode? newMode) {
                          if (newMode != null) {
                            themeProvider.setThemeMode(newMode);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System Default'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light Mode'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark Mode'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Local Data Backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'How it works:\n'
                '• Create Backup Bundle generates a .zip containing all your app data.\n'
                '• Choose a safe folder (like Downloads) on your phone to store it.\n'
                '• To restore later, tap Restore and select your saved .zip file!',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.archive, color: Colors.blue),
                  title: const Text('Create Backup Bundle'),
                  subtitle: const Text('Export current data to a zip file'),
                  onTap: _isLoading ? null : _handleBackup,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.unarchive, color: Colors.green),
                  title: const Text('Restore from Bundle'),
                  subtitle: const Text('Replace local data from a zip backup'),
                  onTap: _isLoading ? null : _handleRestore,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        SafeArea(
          top: false, // Ensure we only handle bottom safe area here
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 40.0),
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'Developed with ❤️',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Janith Karunathilaka',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Syncit - Your Personal Organizer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://buymeacoffee.com/janithrenuka',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.coffee, color: Colors.brown),
                    label: const Text(
                      'Buy me a coffee',
                      style: TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade300,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          bodyContent,
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
