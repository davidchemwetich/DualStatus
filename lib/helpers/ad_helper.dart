import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A helper class for managing Google Mobile Ads.
class AdHelper {
  AdHelper._(); // Private constructor to prevent instantiation.

  /// --- Production Ad Unit IDs ---
  static String get _appOpenAdUnitId {
    return Platform.isAndroid
        ? 'ca-app-pub-6097589894077678/8827552056'
        : 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy'; // Replace with your iOS App Open Ad Unit ID
  }

  static String get _bannerAdUnitId {
    return Platform.isAndroid
        ? 'ca-app-pub-6097589894077678/7150227042'
        : 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy'; // Replace with your iOS Banner Ad Unit ID
  }

  // App Open Ad state
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAppOpenAd = false;
  static DateTime? _appOpenAdLoadTime;

  /// Load App Open Ad (recommended to call at app start)
  static void loadAppOpenAd() {
    if (_isShowingAppOpenAd) return;

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAdLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          // Retry logic could be placed here
        },
      ),
    );
  }

  /// Show App Open Ad if available and valid
  static void showAppOpenAdIfAvailable() {
    if (_appOpenAd == null) {
      loadAppOpenAd();
      return;
    }

    if (_isShowingAppOpenAd) return;

    if (DateTime.now().subtract(const Duration(hours: 4)).isAfter(_appOpenAdLoadTime!)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowingAppOpenAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  /// Create and load a banner ad (caller must dispose)
  static BannerAd createBannerAd() {
    final bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    bannerAd.load();
    return bannerAd;
  }
}
