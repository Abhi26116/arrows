import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../audio/sfx.dart';
import '../config/app_config.dart';
import '../data/progress_store.dart';
import '../services/ads_service.dart';
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
                    _ProductCard(
                      title: l.shopRemoveAds,
                      subtitle: store.removeAdsOwned
                          ? l.shopOwned
                          : (remove?.price ?? l.shopNonConsumable),
                      body: l.shopRemoveAdsBody,
                      owned: store.removeAdsOwned,
                      busy: _busy,
                      onBuy: () => _buy(AppConfig.iapRemoveAds),
                    ),
                    const SizedBox(height: 12),
                    _ProductCard(
                      title: l.shopThemePack,
                      subtitle: store.themePackOwned
                          ? l.shopOwned
                          : (pack?.price ?? l.shopNonConsumable),
                      body: l.shopThemePackBody,
                      owned: store.themePackOwned,
                      busy: _busy,
                      onBuy: () => _buy(AppConfig.iapThemePack),
                    ),
                    const SizedBox(height: 12),
                    _ProductCard(
                      title: l.shopBonusHint,
                      subtitle: store.adsEnabled ? l.shopWatchAnAd : l.shopFree,
                      body: store.adsEnabled
                          ? l.shopBonusHintWatch(store.bonusHints)
                          : l.shopBonusHintFree(store.bonusHints),
                      owned: false,
                      busy: _busy,
                      cta: store.adsEnabled ? l.shopWatch : l.shopClaim,
                      onBuy: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _busy = true);
                        final ok =
                            await AdsService.instance.showRewardedForHint();
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
                        'Debug: products "${AppConfig.iapRemoveAds}" and '
                        '"${AppConfig.iapThemePack}" must exist in Play Console '
                        '/ App Store Connect.',
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
  });

  final String title;
  final String subtitle;
  final String body;
  final bool owned;
  final bool busy;
  final VoidCallback onBuy;
  final String? cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
