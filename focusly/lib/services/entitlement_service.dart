// ─────────────────────────────────────────────────────────────────────────────
// Entitlement Service — decides what the user is allowed to do.
//
// Access model:
//   1. First 90 days from first launch  -> full access, no ads   (free trial)
//   2. After 90 days the user chooses:
//        a) pay $2.99 once  -> full access, no ads, forever
//        b) accept adverts  -> full access, with adverts
//   3. Until they choose, the app shows the choice screen.
//
// The trial date is stored locally. The app is fully offline with no accounts,
// so there is no server to verify against; this is the standard approach for
// offline apps at this price point.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccessState {
  /// Inside the free trial window.
  trial,

  /// Paid the one-time unlock.
  premium,

  /// Trial over, user opted to keep using the app with adverts.
  supportedByAds,

  /// Trial over and no choice made yet — show the choice screen.
  choiceRequired,
}

class EntitlementService extends ChangeNotifier {
  static const int trialDays = 90;

  static const _kFirstLaunch = 'first_launch_iso';
  static const _kPremium = 'premium_unlocked';
  static const _kAdsAccepted = 'ads_accepted';

  DateTime? _firstLaunch;
  bool _premium = false;
  bool _adsAccepted = false;
  bool _ready = false;

  bool get isReady => _ready;
  bool get isPremium => _premium;
  bool get adsAccepted => _adsAccepted;
  DateTime? get firstLaunch => _firstLaunch;

  /// Load state, recording the first-launch date if this is a fresh install.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getString(_kFirstLaunch);
    if (stored == null) {
      _firstLaunch = DateTime.now();
      await prefs.setString(_kFirstLaunch, _firstLaunch!.toIso8601String());
    } else {
      _firstLaunch = DateTime.tryParse(stored) ?? DateTime.now();
    }

    _premium = prefs.getBool(_kPremium) ?? false;
    _adsAccepted = prefs.getBool(_kAdsAccepted) ?? false;
    _ready = true;
    notifyListeners();
  }

  /// Whole days elapsed since first launch.
  int get daysUsed {
    if (_firstLaunch == null) return 0;
    return DateTime.now().difference(_firstLaunch!).inDays;
  }

  /// Days left in the free trial (0 once expired).
  int get daysRemaining {
    final left = trialDays - daysUsed;
    return left < 0 ? 0 : left;
  }

  bool get isTrialActive => !_premium && daysRemaining > 0;

  AccessState get state {
    if (_premium) return AccessState.premium;
    if (daysRemaining > 0) return AccessState.trial;
    if (_adsAccepted) return AccessState.supportedByAds;
    return AccessState.choiceRequired;
  }

  /// True when adverts should be displayed.
  bool get showAds => state == AccessState.supportedByAds;

  /// True when the blocking choice screen must be shown.
  bool get mustChoose => state == AccessState.choiceRequired;

  /// Show a gentle reminder in the last two weeks of the trial.
  bool get shouldNudge =>
      state == AccessState.trial && daysRemaining <= 14;

  /// Called after a successful or restored purchase.
  Future<void> grantPremium() async {
    final prefs = await SharedPreferences.getInstance();
    _premium = true;
    _adsAccepted = false; // paying removes adverts
    await prefs.setBool(_kPremium, true);
    await prefs.setBool(_kAdsAccepted, false);
    notifyListeners();
  }

  /// Called when the user chooses to keep using Focusly with adverts.
  Future<void> acceptAds() async {
    final prefs = await SharedPreferences.getInstance();
    _adsAccepted = true;
    await prefs.setBool(_kAdsAccepted, true);
    notifyListeners();
  }

  /// Debug helper — not reachable from the UI in release builds.
  Future<void> debugResetTrial() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFirstLaunch);
    await prefs.remove(_kPremium);
    await prefs.remove(_kAdsAccepted);
    _premium = false;
    _adsAccepted = false;
    _firstLaunch = null;
    notifyListeners();
  }
}
