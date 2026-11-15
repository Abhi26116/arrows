import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/progress_store.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';

/// Bottom banner slot shared by every screen that shows one.
///
/// Runs an anchored adaptive banner — as wide as the slot, at the height the
/// SDK picks for that width — which earns more than the fixed 320x50. Keeps
/// it clear of the content above with a hairline rule, and takes itself off
/// screen the moment ads are removed.
///
/// The height is reserved before the ad loads, so the screen above does not
/// jump when it arrives — it fades into space that was already there. Until
/// the adaptive size is known, the classic banner height stands in.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_onStoreChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The width comes from MediaQuery, which is not readable in initState.
    if (!_loading) {
      _loading = true;
      _load(MediaQuery.of(context).size.width);
    }
  }

  Future<void> _load(double width) async {
    if (!AppStore.instance.adsEnabled) return;
    // The SDK starts after the consent flow, so it may not be up yet.
    await AdsService.instance.ensureInitialized();
    if (!mounted || !AppStore.instance.adsEnabled) return;

    final size = await AdsService.instance.bannerSize(width);
    if (!mounted || !AppStore.instance.adsEnabled) return;
    setState(() => _size = size);

    AdsService.instance.createBanner(
      size: size,
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
    final size = ad?.size ?? _size ?? AdSize.banner;
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
