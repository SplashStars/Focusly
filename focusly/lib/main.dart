// ─────────────────────────────────────────────────────────────────────────────
// Focusly — Your Daily Planner
//
// Access model (v1.1.1):
//   • Free for 90 days from first launch — every feature, no adverts
//   • After that: pay $2.99 once (no adverts) OR continue free with adverts
//
// The app ALWAYS opens straight into MainScreen for new installs. The upgrade
// choice only appears once the trial has actually elapsed — and from v1.1.4 it
// is also reachable at any time from Settings, so choosing adverts is no
// longer a one-way door.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/project_provider.dart';
import 'services/notification_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/theme_controller.dart';
import 'services/nav_service.dart';
import 'services/locale_controller.dart';
import 'l10n/app_localizations.dart';
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

  // Queue the standing daily nudge. Re-running this every launch also repairs
  // the schedule after a reboot or an app update, when Android drops alarms.
  final dailyReminder = DailyReminderService();
  await dailyReminder.load();

  // Resolve the palette before the first frame, otherwise a light-theme user
  // sees one dark frame on every launch.
  final themeController = ThemeController();
  await themeController.load();

  // Resolve the language before the first frame too, so no screen renders in
  // the wrong language and then swaps.
  final localeController = LocaleController();
  await localeController.load();

  // Resolve entitlement before the first frame so we never flash the wrong screen.
  final entitlement = EntitlementService();
  await entitlement.load();

  runApp(FocuslyApp(
    entitlement: entitlement,
    dailyReminder: dailyReminder,
    themeController: themeController,
    localeController: localeController,
  ));
}

class FocuslyApp extends StatelessWidget {
  final EntitlementService entitlement;
  final DailyReminderService dailyReminder;
  final ThemeController themeController;
  final LocaleController localeController;

  const FocuslyApp({
    super.key,
    required this.entitlement,
    required this.dailyReminder,
    required this.themeController,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => NavService()),
        ChangeNotifierProvider(create: (_) => FocusService()),
        ChangeNotifierProvider<EntitlementService>.value(value: entitlement),
        ChangeNotifierProvider<DailyReminderService>.value(value: dailyReminder),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
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
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, themes, locales, _) {
          return MaterialApp(
            title: 'Focusly - Daily Planner',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themes.isDark ? ThemeMode.dark : ThemeMode.light,
            // Arabic flips the whole layout; Flutter handles that from the
            // locale, which is why this is set rather than left to the device.
            locale: locales.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _AccessGate(),
          );
        },
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
