import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncit/screens/home_screen.dart';
import 'package:syncit/services/auth_service.dart';
import 'package:syncit/services/backup_service.dart';
import 'package:syncit/services/notification_service.dart';
import 'package:syncit/services/storage_service.dart';
import 'package:syncit/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider.value(value: storageService),
        Provider.value(value: notificationService),
        ProxyProvider2<AuthService, StorageService, BackupService>(
          update: (_, auth, storage, __) => BackupService(auth, storage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemindeMe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
