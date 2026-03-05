import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncit/screens/home_screen.dart';
import 'package:syncit/utils/theme.dart';
import 'package:syncit/models/checklist.dart';
import 'package:syncit/models/note.dart';
import 'package:syncit/models/reminder.dart';
import 'package:syncit/models/todo.dart';
import 'package:syncit/services/notification_service.dart';
import 'package:syncit/utils/navigator_key.dart';
import 'package:provider/provider.dart';
import 'package:syncit/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(ChecklistAdapter());
  Hive.registerAdapter(ChecklistItemAdapter());
  Hive.registerAdapter(NoteAdapter());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Syncit',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
