// ─────────────────────────────────────────────────────────────────────────────
// Locale Controller — which of the 10 languages the app speaks.
//
// L10n.t is a global, deliberately. Notification scheduling, the models and the
// focus service all produce user-facing text and none of them has a
// BuildContext, so AppLocalizations.of(context) is not reachable there. This
// mirrors the AppColors pattern already used for theming.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Global access to the current translations.
class L10n {
  static AppLocalizations t = lookupAppLocalizations(const Locale('en'));
}

class LocaleController extends ChangeNotifier {
  static const _kLocale = 'app_locale';

  /// null means "follow the device language".
  Locale? _locale;
  Locale? get locale => _locale;

  static const List<Locale> supported = [
    Locale('en'),
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Endonyms: a language is listed the way its own speakers write it, so the
  /// picker is usable by someone who cannot read the current language.
  static const Map<String, String> names = {
    'en': 'English',
    'ar': 'العربية',
    'bn': 'বাংলা',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    'hi': 'हिन्दी',
    'id': 'Bahasa Indonesia',
    'pt': 'Português',
    'zh': '中文',
  };

  static bool _isSupported(String code) =>
      supported.any((l) => l.languageCode == code);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocale);
    if (code != null && _isSupported(code)) _locale = Locale(code);
    _apply();
  }

  Future<void> setLocale(Locale? value) async {
    _locale = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kLocale);
    } else {
      await prefs.setString(_kLocale, value.languageCode);
    }
    _apply();
    notifyListeners();
  }

  /// What the app actually renders in: the saved choice, else the first device
  /// language we support, else English.
  Locale get effective => _locale ?? _deviceOrEnglish();

  Locale _deviceOrEnglish() {
    for (final l in WidgetsBinding.instance.platformDispatcher.locales) {
      if (_isSupported(l.languageCode)) return Locale(l.languageCode);
    }
    return const Locale('en');
  }

  /// Label for the current setting, in the language it refers to.
  String get currentLabel =>
      _locale == null ? 'System' : (names[_locale!.languageCode] ?? _locale!.languageCode);

  void _apply() => L10n.t = lookupAppLocalizations(effective);
}
