import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/progress_store.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';

/// Bottom banner slot shared by every screen that shows one.
///
/// Centres the ad (a 320pt banner in a full-width column would otherwise sit
/// against the left edge), keeps it clear of the content above with a hairline
/// rule, and takes itself off screen the moment ads are removed.
///
/// The banner's height is reserved from the first frame, so the screen above
/// does not jump when the ad finishes loading — it fades into space that was
/// always there.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_onStoreChanged);
    _load();
  }

  Future<void> _load() async {
    if (!AppStore.instance.adsEnabled) return;
    // The SDK starts after the consent flow, so it may not be up yet.
    await AdsService.instance.ensureInitialized();
    if (!mounted || !AppStore.instance.adsEnabled) return;

    AdsService.instance.createBanner(
      onLoaded: (ad) {
        // The screen can go away before the ad finishes loading.
        if (!mounted || !AppStore.instance.adsEnabled) {
          ad.dispose();
          return;
        }
        setState(() => _ad = ad);
      },
    );
  }

  void _onStoreChanged() {
    if (AppStore.instance.adsEnabled || _ad == null) return;
    _ad!.dispose();
    _ad = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onStoreChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to reserve once ads are gone for good.
    if (!AppStore.instance.adsEnabled) return const SizedBox.shrink();

    final ad = _ad;
    final size = ad?.size ?? AdSize.banner;
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            // The rule only appears with the ad; an empty slot stays invisible.
            color: ad == null
                ? Colors.transparent
                : AppColors.surfaceHigh.withOpacity(0.6),
          ),
        ),
      ),
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: ad == null
            ? null
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                builder: (context, value, child) =>
                    Opacity(opacity: value, child: child),
                child: AdWidget(ad: ad),
              ),
      ),
    );
  }
}
