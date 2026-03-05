import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/providers/theme_provider.dart';
import 'package:syncit/screens/settings_screen.dart';
import 'package:syncit/widgets/add_options_fab.dart';

import 'package:syncit/screens/dashboard_screen.dart';
import 'package:syncit/screens/reminders_screen.dart';
import 'package:syncit/screens/todos_screen.dart';
import 'package:syncit/screens/checklists_screen.dart';
import 'package:syncit/screens/notes_screen.dart';
import 'package:syncit/services/permission_service.dart';
import 'package:syncit/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService().checkAndRequestPermissions(context);
      NotificationService().handleAppLaunchNotification();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour < 17) {
      return 'Good Afternoon 🌤️';
    } else {
      return 'Good Evening 🌙';
    }
  }

  // Generate a distinct key every time we need to force
  // child screens to re-initialize and fetch latest data from Hive.
  Key _refreshKey = UniqueKey();

  List<Widget> _buildScreens() {
    return [
      DashboardScreen(
        key: ValueKey('dash_$_refreshKey'),
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      RemindersScreen(key: ValueKey('rem_$_refreshKey')),
      TodosScreen(key: ValueKey('todo_$_refreshKey')),
      ChecklistsScreen(key: ValueKey('check_$_refreshKey')),
      NotesScreen(key: ValueKey('note_$_refreshKey')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark =
                themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);
            return Transform.scale(
              scale: 0.9,
              child: Switch(
                value: isDark,
                activeThumbColor: Colors.deepPurple.shade300,
                inactiveThumbColor: Colors.yellow.shade700,
                inactiveTrackColor: Colors.yellow.shade200,
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return const Icon(Icons.dark_mode, color: Colors.white);
                  }
                  return const Icon(Icons.light_mode, color: Colors.white);
                }),
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            );
          },
        ),
        title: Text(
          _getGreeting(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildScreens()[_currentIndex],
      floatingActionButton: AddOptionsFab(
        onRefresh: () {
          // Update the refresh key to force Flutter to recreate the widget tree
          // and hit initState on the active tab.
          setState(() {
            _refreshKey = UniqueKey();
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            backgroundColor: Colors.black,
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            backgroundColor: Colors.blue,
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: 'Todos',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            backgroundColor: Colors.orange,
            label: 'Checklists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: 'Notes',
            backgroundColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}
