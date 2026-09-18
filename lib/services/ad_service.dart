import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _isInitialized = false;

  /// Initialize Mobile Ads SDK — call once at app startup
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');
    } catch (e) {
      debugPrint('AdMob initialization failed: $e');
    }
  }

  /// Banner Ad Unit ID
  /// Uses test IDs during development. Replace with your real IDs before release.
  /// 
  /// To get real IDs:
  /// 1. Create account at https://admob.google.com
  /// 2. Add your app
  /// 3. Create a Banner ad unit
  /// 4. Replace the IDs below
  static String get bannerAdUnitId {
    if (kIsWeb) return ''; // No ads on web
    if (Platform.isAndroid) {
      // Test Banner Ad Unit ID for Android
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // Test Banner Ad Unit ID for iOS
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  /// AdMob App ID (used in AndroidManifest.xml / Info.plist)
  /// Test App ID — replace with your real App ID before release
  static String get appId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544~3347511713'; // Test App ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544~1458002511'; // Test App ID
    }
    return '';
  }

  /// Create a banner ad with standard size
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
