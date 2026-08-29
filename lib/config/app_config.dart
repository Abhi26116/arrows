/// Central knobs for monetization + Firebase.
class AppConfig {
  AppConfig._();

  /// Set `true` after running `flutterfire configure` and filling
  /// [DefaultFirebaseOptions] in `lib/firebase/firebase_options.dart`.
  static const bool firebaseEnabled = false;

  /// Live ads are opt-in: only builds passing `--dart-define=LIVE_ADS=true`
  /// serve them. Everything else — including `flutter run --release` on a test
  /// device — gets Google's sample ads.
  ///
  /// The store workflows in `codemagic.yaml` pass the flag. Never test a live
  /// build by tapping your own ads; that can get the AdMob account suspended.
  static const bool useLiveAds = bool.fromEnvironment('LIVE_ADS');

  // —— Live AdMob IDs ——
  //
  // The app IDs are also duplicated natively, and all three must agree.
  //   android/app/src/main/AndroidManifest.xml → com.google.android.gms.ads.APPLICATION_ID
  //   ios/Runner/Info.plist                    → GADApplicationIdentifier

  static const androidAdmobAppId = 'ca-app-pub-9350608203842553~3050594303';
  static const iosAdmobAppId = 'ca-app-pub-9350608203842553~3329745579';

  static const androidBannerAdUnitId =
      'ca-app-pub-9350608203842553/8111349297';
  static const iosBannerAdUnitId = 'ca-app-pub-9350608203842553/6111871911';

  static const androidInterstitialAdUnitId =
      'ca-app-pub-9350608203842553/9895153921';
  static const iosInterstitialAdUnitId =
      'ca-app-pub-9350608203842553/9631430049';

  static const androidRewardedAdUnitId =
      'ca-app-pub-9350608203842553/1264915513';
  static const iosRewardedAdUnitId = 'ca-app-pub-9350608203842553/5920300221';

  /// Extra belt-and-braces: devices here always get test ads, even in a live
  /// build. Grab the id from the device log line "To get test ads on this
  /// device, set: … testDeviceIdentifiers = [ "<id>" ]".
  static const List<String> testDeviceIds = <String>[];

  // Create these non-consumable products in Play Console / App Store Connect.
  static const iapRemoveAds = 'arrows_remove_ads';
  static const iapThemePack = 'arrows_theme_pack';

  static const leaderboardCollection = 'leaderboard';
}

/// Google's public sample ad units, used automatically in debug builds.
class AdTestIds {
  AdTestIds._();

  static const androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
}
