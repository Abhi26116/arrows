import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;

import '../audio/sfx.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/progress_store.dart';
import '../logic/daily_challenge.dart';
import '../logic/level_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';
import 'daily_history_screen.dart';
import 'game_screen.dart';
import '../services/update_service.dart';
import 'how_to_play_screen.dart';
import 'language_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'themes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  Future<void> _onFirstFrame() async {
    await _maybeShowOnboarding();
    if (mounted) await _maybeOfferUpdate();
  }

  /// Language first, then the rules — there is no point explaining the game in
  /// a language the player did not choose.
  Future<void> _maybeShowOnboarding() async {
    final store = AppStore.instance;
    if (!store.chosenLanguage) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LanguageScreen(onboarding: true),
        ),
      );
    }
    if (store.seenHowTo) {
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HowToPlayScreen(fromOnboarding: true),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Checked on the home screen rather than at launch: it is a network call,
  /// and it must never be the reason the game is slow to open.
  Future<void> _maybeOfferUpdate() async {
    if (!await UpdateService.instance.check()) return;
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final version = UpdateService.instance.available;
    final update = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.updateTitle,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l.updateBody(version ?? ''),
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(l.updateLater, style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.updateNow),
          ),
        ],
      ),
    );
    if (update == true) {
      await UpdateService.instance.start();
    } else {
      await UpdateService.instance.declined();
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) => _buildHome(context),
    );
  }

  Widget _buildHome(BuildContext context) {
    final store = AppStore.instance;
    final continueLevel = store.maxUnlocked.clamp(1, LevelCatalog.count);
    final dailyBest = store.dailyBestStars;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Hero art scales with the space left over, so short
                      // phones (and the reserved ad slot) never squeeze the
                      // buttons off the bottom.
                      final heroHeight =
                          (constraints.maxHeight * 0.24).clamp(96.0, 175.0);
                      return Column(
                        children: [
                          Row(
                            children: [
                              CircleIconButton(
                                icon: Icons.shopping_bag_outlined,
                                tooltip: 'Shop',
                                size: 44,
                                onTap: () => _open(const ShopScreen()),
                              ),
                              const Spacer(),
                              CircleIconButton(
                                icon: Icons.settings_rounded,
                                tooltip: 'Settings',
                                size: 44,
                                onTap: () => _open(const SettingsScreen()),
                              ),
                            ],
                          ),
                          const Spacer(flex: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'ARROWS',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontVariations: const [
                                  FontVariation('wght', 700)
                                ],
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                                letterSpacing: 2,
                                color: AppColors.ink,
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(
                              begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                          const SizedBox(height: 8),
                          Text(
                            'Clear the board. Order is everything.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniStat(
                                icon: Icons.star_rounded,
                                value: '${store.totalStars}',
                                label: 'stars',
                              ),
                              const SizedBox(width: 16),
                              _MiniStat(
                                icon: Icons.local_fire_department_rounded,
                                value: '${store.dailyStreak}',
                                label: 'streak',
                              ),
                              const SizedBox(width: 16),
                              _MiniStat(
                                icon: Icons.flag_rounded,
                                value: '${store.clearedCount}',
                                label: 'cleared',
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          MiniBoardArt(height: heroHeight),
                          const Spacer(flex: 1),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                SoundService.instance.play(Sfx.tap);
                                _open(GameScreen(levelId: continueLevel));
                              },
                              child: Text(
                                continueLevel <= 1 && store.clearedCount == 0
                                    ? 'Play'
                                    : 'Continue · $continueLevel',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    SoundService.instance.play(Sfx.tap);
                                    _open(
                                      GameScreen(
                                        customLevel:
                                            DailyChallenge.levelForToday(),
                                        isDaily: true,
                                      ),
                                    );
                                  },
                                  style: _outlineStyle(),
                                  child: dailyBest == null
                                      ? const Text('Daily')
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('Daily · '),
                                            Text('$dailyBest'),
                                            Icon(Icons.star_rounded,
                                                size: 15,
                                                color: AppColors.accentSoft),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    SoundService.instance.play(Sfx.tap);
                                    _open(const LevelSelectScreen());
                                  },
                                  style: _outlineStyle(),
                                  child: const Text('Levels'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Quick(
                                icon: Icons.palette_outlined,
                                label: 'Themes',
                                onTap: () => _open(const ThemesScreen()),
                              ),
                              _Quick(
                                icon: Icons.history_rounded,
                                label: 'Streak',
                                onTap: () => _open(const DailyHistoryScreen()),
                              ),
                              _Quick(
                                icon: Icons.help_outline_rounded,
                                label: 'How to',
                                onTap: () => _open(const HowToPlayScreen()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlineStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      side: BorderSide(color: AppColors.surfaceHigh),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontVariations: [FontVariation('wght', 700)],
          fontWeight: FontWeight.w700,
          fontSize: 14),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Icon(icon, color: AppColors.ink, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accentSoft),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontVariations: const [FontVariation('wght', 700)],
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
