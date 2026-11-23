// ─────────────────────────────────────────────────────────────────────────────
// Theme Controller — light / dark / follow-system.
//
// AppColors is a set of global statics rather than something read from
// BuildContext, so the palette has to be swapped BEFORE the tree rebuilds.
// That is why this calls AppColors.apply() and only then notifies listeners.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

enum AppThemeMode {
  system('Follow system'),
  light('Light'),
  dark('Dark');

  const AppThemeMode(this.label);
  final String label;
}

class ThemeController extends ChangeNotifier {
  static const _kMode = 'theme_mode';

  // Dark is the historical look, so it stays the default for existing users.
  AppThemeMode _mode = AppThemeMode.dark;
  Brightness _platformBrightness = Brightness.dark;

  AppThemeMode get mode => _mode;

  Brightness get effectiveBrightness {
    switch (_mode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return _platformBrightness;
    }
  }

  bool get isDark => effectiveBrightness == Brightness.dark;

  AppPalette get palette => isDark ? AppPalette.dark : AppPalette.light;

  ThemeData get theme => AppTheme.themeFor(palette);

  Future<void> load() async {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    _platformBrightness = dispatcher.platformBrightness;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kMode);
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => AppThemeMode.dark,
    );

    // Follow the OS while the app is open, not just at launch.
    dispatcher.onPlatformBrightnessChanged = () {
      _platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (_mode == AppThemeMode.system) _applyAndNotify();
    };

    _applyAndNotify();
  }

  Future<void> setMode(AppThemeMode value) async {
    if (_mode == value) return;
    _mode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode, value.name);
    _applyAndNotify();
  }

  void _applyAndNotify() {
    AppColors.apply(palette);
    _syncSystemBars();
    notifyListeners();
  }

  /// Status-bar icons must contrast with the header, and the gesture bar with
  /// the app background. Getting this wrong leaves invisible system icons.
  void _syncSystemBars() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // The header gradient stays deep purple in both themes, so status bar
        // icons stay light regardless of the palette.
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: palette.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
