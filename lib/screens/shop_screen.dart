import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:arrows_game/l10n/app_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show ProductDetails;

import '../audio/sfx.dart';
import '../config/app_config.dart';
import '../data/progress_store.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Analytics.instance.track('shop_open');
    // Purchases land through the store stream, after buy() has returned.
    AppStore.instance.addListener(_onStoreChanged);
    // Prices may not have arrived yet if the shop opens soon after launch.
    if (IapService.instance.products.isEmpty) {
      IapService.instance.queryProducts().then((_) => _onStoreChanged());
    }
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  Future<void> _buy(String id) async {
    setState(() => _busy = true);
    SoundService.instance.play(Sfx.tap);
    final ok = await IapService.instance.buy(id);
    if (!ok && kDebugMode) {
      await IapService.instance.unlockForTesting(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug unlock applied (no store product found)'),
          ),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppStore.instance;
    final iap = IapService.instance;
    final remove = iap.product(AppConfig.iapRemoveAds);
    final pack = iap.product(AppConfig.iapThemePack);
    final bundle = iap.product(AppConfig.iapBundle);
    final hints15 = iap.product(AppConfig.iapHints15);
    final hints60 = iap.product(AppConfig.iapHints60);
    final ownsEverything = store.removeAdsOwned && store.themePackOwned;

    String price(ProductDetails? product, String fallback) =>
        product?.price ?? fallback;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(title: l.shopTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (!ownsEverything) ...[
                      _ProductCard(
                        title: l.shopBundle,
                        subtitle: price(bundle, l.shopNonConsumable),
                        body: l.shopBundleBody(
                            AppConfig.hintsPerProduct[AppConfig.iapBundle]!),
                        badge: l.shopBestValue,
                        owned: false,
                        busy: _busy,
                        onBuy: () => _buy(AppConfig.iapBundle),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _ProductCard(
                      title: l.shopRemoveAds,
                      subtitle: store.removeAdsOwned
                          ? l.shopOwned
                          : price(remove, l.shopNonConsumable),
                      body: l.shopRemoveAdsBody(
                          AppConfig.hintsPerProduct[AppConfig.iapRemoveAds]!),
                      owned: store.removeAdsOwned,
                      busy: _busy,
                      onBuy: () => _buy(AppConfig.iapRemoveAds),
                    ),
                    const SizedBox(height: 12),
                    _ProductCard(
                      title: l.shopThemePack,
                      subtitle: store.themePackOwned
                          ? l.shopOwned
                          : price(pack, l.shopNonConsumable),
                      body: l.shopThemePackBody,
                      owned: store.themePackOwned,
                      busy: _busy,
                      onBuy: () => _buy(AppConfig.iapThemePack),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 22, bottom: 10),
                      child: Text(
                        l.shopHintsHeader(store.bonusHints),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontVariations: const [FontVariation('wght', 700)],
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _ProductCard(
                      title: l.shopHintPack(15),
                      subtitle: price(hints15, l.shopConsumable),
                      body: l.shopHintPackBody,
                      owned: false,
                      busy: _busy,
                      onBuy: () => _buy(AppConfig.iapHints15),
                    ),
                    const SizedBox(height: 12),
                    _ProductCard(
                      title: l.shopHintPack(60),
                      subtitle: price(hints60, l.shopConsumable),
                      body: l.shopHintPackBody,
                      badge: l.shopBestValue,
                      owned: false,
                      busy: _busy,
                      onBuy: () => _buy(AppConfig.iapHints60),
                    ),
                    const SizedBox(height: 12),
                    _ProductCard(
                      title: l.shopBonusHint,
                      subtitle: l.shopWatchAnAd,
                      body: l.shopBonusHintWatch(store.bonusHints),
                      owned: false,
                      busy: _busy,
                      cta: l.shopWatch,
                      onBuy: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _busy = true);
                        final ok = await AdsService.instance
                            .showRewardedForHint(placement: 'shop_hint');
                        if (mounted) {
                          setState(() => _busy = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? l.shopHintAdded : l.shopAdNotReady,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              await IapService.instance.restore();
                              if (mounted) setState(() => _busy = false);
                            },
                      child: Text(l.shopRestore),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.shopRestoreNote,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    if (kDebugMode && !AppConfig.screenshotMode) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Debug: products ${IapService.productIds.join(', ')} '
                        'must exist in Play Console / App Store Connect.',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.owned,
    required this.busy,
    required this.onBuy,
    this.cta,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String body;
  final bool owned;
  final bool busy;
  final VoidCallback onBuy;
  final String? cta;

  /// A short tag over the title, such as "Best value"; it also outlines the
  /// card in the accent colour.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badge == null ? AppColors.surfaceHigh : AppColors.accent,
          width: badge == null ? 1 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge.toUpperCase(),
                style: TextStyle(
                  color: AppColors.accentSoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontVariations: [FontVariation('wght', 700)],
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(subtitle, style: TextStyle(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: owned || busy ? null : onBuy,
              child: Text(owned
                  ? AppLocalizations.of(context).shopOwned
                  : (cta ?? AppLocalizations.of(context).shopBuy)),
            ),
          ),
        ],
      ),
    );
  }
}
