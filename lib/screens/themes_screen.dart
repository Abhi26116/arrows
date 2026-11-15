import 'package:flutter/material.dart';
import 'package:arrows_game/l10n/app_localizations.dart';

import '../audio/sfx.dart';
import '../config/app_config.dart';
import '../data/progress_store.dart';
import '../models/direction.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../theme/game_themes.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';
import 'shop_screen.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  @override
  void initState() {
    super.initState();
    // A trial may have run out since the theme was last applied.
    ThemeController.instance.load();
  }

  Future<void> _openShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
    if (mounted) setState(() {});
  }

  /// A locked theme: a day of it for one rewarded ad, or all of them for
  /// good from the shop.
  Future<void> _offerTrial(GameTheme theme) async {
    final l = AppLocalizations.of(context);
    final pack = IapService.instance.product(AppConfig.iapThemePack);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.themesTrialTitle(theme.name),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontVariations: const [FontVariation('wght', 700)],
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.themesTrialBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'ad'),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: Text(l.themesTrialWatch),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'shop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(color: AppColors.surfaceHigh),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(pack == null
                    ? l.themesUnlockInShop
                    : l.themesUnlockAll(pack.price)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.hintOutLater,
                    style: TextStyle(color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'shop') return _openShop();
    if (choice != 'ad') return;

    final earned =
        await AdsService.instance.showRewardedForThemeTrial(theme.id);
    if (!mounted) return;
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.shopAdNotReady)),
      );
      return;
    }
    Analytics.instance.track('theme_trial', {'theme': theme.id});
    await ThemeController.instance.setTheme(theme.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = AppStore.instance.themePackOwned;
    final active = ThemeController.instance.theme.id;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(title: AppLocalizations.of(context).themesTitle),
              if (!owned)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        SoundService.instance.play(Sfx.tap);
                        _openShop();
                      },
                      child:
                          Text(AppLocalizations.of(context).themesUnlockInShop),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: GameThemes.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final theme = GameThemes.all[i];
                    final locked =
                        !ThemeController.instance.canUse(theme);
                    final trialUntil = theme.premium && !owned
                        ? AppStore.instance.themeTrialUntil(theme.id)
                        : null;
                    final trialHours = trialUntil == null || locked
                        ? null
                        : (trialUntil.difference(DateTime.now()).inMinutes /
                                60)
                            .ceil()
                            .clamp(1, 24);
                    final selected = theme.id == active;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: locked
                          ? () {
                              SoundService.instance.play(Sfx.tap);
                              _offerTrial(theme);
                            }
                          : () async {
                              SoundService.instance.play(Sfx.tap);
                              await ThemeController.instance.setTheme(theme.id);
                              if (mounted) setState(() {});
                            },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [theme.bgTop, theme.bgBottom],
                          ),
                          border: Border.all(
                            color: selected ? theme.accent : theme.surfaceHigh,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.name,
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontVariations: const [
                                        FontVariation('wght', 700)
                                      ],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: theme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    locked
                                        ? l.themesLocked
                                        : trialHours != null
                                            ? l.themesTrialLeft(trialHours)
                                            : selected
                                                ? l.themesActive
                                                : theme.premium
                                                    ? l.themesPremium
                                                    : l.themesFree,
                                    style: TextStyle(
                                      color: theme.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Preview shows what the board actually looks
                            // like in this theme, not the old dot palette.
                            Container(
                              width: 66,
                              height: 46,
                              decoration: BoxDecoration(
                                color: theme.bgTop,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.surfaceHigh),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ArrowGlyph(
                                    direction: Direction.right,
                                    color: theme.arrowLine,
                                    size: 24,
                                  ),
                                  ArrowGlyph(
                                    direction: Direction.left,
                                    color: theme.arrowLine.withOpacity(0.7),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              locked
                                  ? Icons.lock_rounded
                                  : selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                              color: theme.accentSoft,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
