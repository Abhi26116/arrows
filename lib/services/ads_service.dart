import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import '../data/progress_store.dart';
import 'consent_service.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _ready = false;
  Completer<void>? _initialised;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;

  /// Whether the SDK finished starting up (successfully or not).
  bool get isReady => _ready;

  Future<void>? _startup;

  /// The one way in. Runs the consent flow and then starts the SDK, once,
  /// however many callers ask.
  ///
  /// Both the splash and every banner slot call this: the SDK now starts after
  /// consent, so a screen can easily be built before it is up, and a banner
  /// created too early silently never appears. Assigning the future before the
  /// first await keeps concurrent callers on the same run, so ads can never
  /// start ahead of consent.
  Future<void> ensureInitialized() => _startup ??= _bootstrap();

  Future<void> _bootstrap() async {
    await ConsentService.instance.gather();
    await init();
  }

  Future<void> init() async {
    final pending = _initialised;
    if (pending != null) return pending.future;
    final completer = _initialised = Completer<void>();
    try {
      await MobileAds.instance.initialize();
      if (AppConfig.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AppConfig.testDeviceIds),
        );
      }
      _ready = true;
      if (AppStore.instance.adsEnabled) {
        loadRewarded();
        loadInterstitial();
      }
    } catch (e) {
      debugPrint('Ads init failed: $e');
      _ready = false;
    }
    completer.complete();
  }

  /// Live units only for builds that explicitly opted in; never in debug.
  static bool get _live => AppConfig.useLiveAds && !kDebugMode;

  String get _bannerId => Platform.isIOS
      ? (_live ? AppConfig.iosBannerAdUnitId : AdTestIds.iosBanner)
      : (_live ? AppConfig.androidBannerAdUnitId : AdTestIds.androidBanner);

  String get _rewardedId => Platform.isIOS
      ? (_live ? AppConfig.iosRewardedAdUnitId : AdTestIds.iosRewarded)
      : (_live ? AppConfig.androidRewardedAdUnitId : AdTestIds.androidRewarded);

  String get _interstitialId => Platform.isIOS
      ? (_live
          ? AppConfig.iosInterstitialAdUnitId
          : AdTestIds.iosInterstitial)
      : (_live
          ? AppConfig.androidInterstitialAdUnitId
          : AdTestIds.androidInterstitial);

  BannerAd? createBanner({required void Function(BannerAd) onLoaded}) {
    if (!_ready || !AppStore.instance.adsEnabled) return null;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerId,
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );
    ad.load();
    return ad;
  }

  void loadRewarded() {
    if (!_ready || !AppStore.instance.adsEnabled) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: $error');
          _rewarded = null;
        },
      ),
    );
  }

  void loadInterstitial() {
    if (!_ready || !AppStore.instance.adsEnabled) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: $error');
          _interstitial = null;
        },
      ),
    );
  }

  Future<bool> showRewardedForHint() =>
      _showRewarded(onReward: () => AppStore.instance.addBonusHints(1));

  /// Extra heart after running out of lives — same rewarded unit, no payload.
  Future<bool> showRewardedForExtraLife() => _showRewarded();

  Future<bool> _showRewarded({Future<void> Function()? onReward}) async {
    if (!AppStore.instance.adsEnabled) {
      // Ads removed — grant the reward directly.
      await onReward?.call();
      return true;
    }
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return false;
    }
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) async {
        earned = true;
        await onReward?.call();
      },
    );
    return earned;
  }

  Future<void> maybeShowInterstitialAfterWin() async {
    if (!AppStore.instance.adsEnabled) return;
    await AppStore.instance.bumpWinForAds();
    if (AppStore.instance.winsSinceInterstitial < 3) return;
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
    );
    await ad.show();
    await AppStore.instance.resetWinsSinceInterstitial();
  }

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
