// ─────────────────────────────────────────────────────────────────────────────
// Focusly — Your Daily Planner
// Entry point: initializes notifications and wires up all providers
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/project_provider.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';

void main() async {
  // Required before using any async Flutter APIs
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notifications (FREE reminders for all users)
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  // Make status bar transparent (blends with purple header)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FocuslyApp());
}

class FocuslyApp extends StatelessWidget {
  const FocuslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'Focusly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}
