// ─────────────────────────────────────────────────────────────────────────────
// Ads Service — banner adverts for users who chose ads over the $2.99 unlock.
//
// Adverts are ONLY loaded when EntitlementService.showAds is true, i.e. the
// 90-day trial has ended and the user explicitly chose adverts. Trial users
// and paying users never see an advert.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdConfig {
  /// Google's official TEST banner unit. Safe to ship while AdMob is pending —
  /// it serves real-looking test ads and never generates invalid traffic.
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// Real AdMob banner unit id (AdMob app: Focusly - Daily Planner).
  static const String prodBanner = 'ca-app-pub-3026343596333452/6605493259';

  /// Uses the production unit when configured, otherwise the test unit.
  static String get bannerUnitId {
    if (kReleaseMode && prodBanner.isNotEmpty) return prodBanner;
    return testBanner;
  }

  /// True once a real AdMob unit has been wired in.
  static bool get isConfigured => prodBanner.isNotEmpty;
}

class AdsService extends ChangeNotifier {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    notifyListeners();
  }

  /// Create a fresh banner. The caller owns disposal.
  BannerAd createBanner({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    return BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }
}
