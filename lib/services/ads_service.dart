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
      ? (_live ? AppConfig.iosInterstitialAdUnitId : AdTestIds.iosInterstitial)
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
    // Hand the ad over now: show() returns long before the ad closes, and a
    // second caller must not be able to show this same one.
    _rewarded = null;

    // show() completes once the ad has been *presented*, not once the viewer
    // is done with it, and the reward arrives later still. Returning at that
    // point reported failure for every ad anyone ever watched. Wait for the
    // ad to close instead.
    final closed = Completer<bool>();
    var earned = false;
    void finish() {
      if (!closed.isCompleted) closed.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded failed to show: $error');
        ad.dispose();
        loadRewarded();
        finish();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) async {
        earned = true;
        await onReward?.call();
      },
    );

    // If the SDK never reports the ad closing, honour whatever was earned
    // rather than leaving the caller waiting on a future that never lands.
    return closed.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => earned,
    );
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
    _interstitial = null;

    // Same as the rewarded ad: show() returns as soon as the ad is on screen.
    // Returning there let the win panel and the next screen run underneath it.
    final closed = Completer<bool>();
    void finish({required bool shown}) {
      if (!closed.isCompleted) closed.complete(shown);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
        finish(shown: true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        loadInterstitial();
        finish(shown: false);
      },
    );

    await ad.show();
    final shown = await closed.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => true,
    );
    // Only spend the counter on an ad the player actually saw, so a failed
    // show does not cost them three wins' worth of quiet.
    if (shown) await AppStore.instance.resetWinsSinceInterstitial();
  }

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
