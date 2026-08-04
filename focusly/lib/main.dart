// ─────────────────────────────────────────────────────────────────────────────
// Focusly — Your Daily Planner
//
// Access model (v1.1.1):
//   • Free for 90 days from first launch — every feature, no adverts
//   • After that: pay $2.99 once (no adverts) OR continue free with adverts
//
// The app ALWAYS opens straight into MainScreen for new installs. The upgrade
// choice only appears once the trial has actually elapsed.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/project_provider.dart';
import 'services/notification_service.dart';
import 'services/focus_service.dart';
import 'services/entitlement_service.dart';
import 'services/iap_service.dart';
import 'services/ads_service.dart';
import 'screens/main_screen.dart';
import 'screens/upgrade/upgrade_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  // Resolve entitlement before the first frame so we never flash the wrong screen.
  final entitlement = EntitlementService();
  await entitlement.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(FocuslyApp(entitlement: entitlement));
}

class FocuslyApp extends StatelessWidget {
  final EntitlementService entitlement;
  const FocuslyApp({super.key, required this.entitlement});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => FocusService()),
        ChangeNotifierProvider<EntitlementService>.value(value: entitlement),
        ChangeNotifierProvider(create: (_) => AdsService()),
        ChangeNotifierProvider(
          create: (_) {
            final iap = IAPService();
            // Persist the unlock whenever a purchase completes or is restored.
            iap.onUnlocked = entitlement.grantPremium;
            iap.initialize();
            return iap;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Focusly - Daily Planner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AccessGate(),
      ),
    );
  }
}

/// Routes to the app or the upgrade choice depending on entitlement state.
class _AccessGate extends StatelessWidget {
  const _AccessGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementService>(
      builder: (context, ent, _) {
        if (ent.mustChoose) return const UpgradeScreen();
        return const MainScreen();
      },
    );
  }
}
