import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../data/progress_store.dart';
import '../logic/level_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

/// Levels shown beyond the furthest unlocked one.
const int _lookahead = 6;

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final levels = LevelCatalog.all;
    final store = AppStore.instance;

    // Only ever show a little way past the player's frontier — the list must
    // not expose how many levels the game actually holds.
    final frontierLevel = store.maxUnlocked.clamp(1, LevelCatalog.count);
    final frontier =
        (store.maxUnlocked + _lookahead).clamp(1, LevelCatalog.count);
    final packs = LevelCatalog.packs
        .where((p) => p.startId <= frontier)
        .toList(growable: false);

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'Levels',
                trailing: Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 18, color: AppColors.accentSoft),
                    const SizedBox(width: 4),
                    Text(
                      '${store.totalStars}',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.accentSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: packs.length + 1,
                  itemBuilder: (context, packIndex) {
                    if (packIndex == packs.length) {
                      return const _MoreAhead();
                    }
                    final pack = packs[packIndex];
                    final packLevels = levels
                        .where((l) =>
                            l.id >= pack.startId &&
                            l.id <= pack.endId &&
                            l.id <= frontier)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 10),
                          child: Text(
                            pack.name,
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontVariations: const [
                                FontVariation('wght', 700)
                              ],
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: packLevels.length,
                          itemBuilder: (context, index) {
                            final level = packLevels[index];
                            final unlocked = store.isUnlocked(level.id);
                            final stars = store.starsFor(level.id);
                            return _LevelTile(
                              id: level.id,
                              unlocked: unlocked,
                              isCurrent: unlocked && level.id == frontierLevel,
                              stars: stars,
                              onTap: unlocked
                                  ? () async {
                                      SoundService.instance.play(Sfx.tap);
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              GameScreen(levelId: level.id),
                                        ),
                                      );
                                      if (mounted) setState(() {});
                                    }
                                  : null,
                            );
                          },
                        ),
                      ],
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

/// Footer so the visible end of the list never reads as the end of the game.
class _MoreAhead extends StatelessWidget {
  const _MoreAhead();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Column(
        children: [
          Icon(Icons.more_horiz_rounded, color: AppColors.muted, size: 22),
          const SizedBox(height: 6),
          Text(
            'More open up as you clear levels',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.id,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    required this.onTap,
  });

  final int id;
  final bool unlocked;

  /// The furthest board reached — the one to play next.
  final bool isCurrent;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cleared = stars > 0;
    final Color background;
    final Color border;
    if (isCurrent) {
      background = AppColors.accent.withOpacity(0.16);
      border = AppColors.accent;
    } else if (cleared) {
      background = AppColors.surface;
      border = AppColors.accent.withOpacity(0.35);
    } else if (unlocked) {
      background = AppColors.surface;
      border = AppColors.surfaceHigh;
    } else {
      background = AppColors.surface.withOpacity(0.4);
      border = Colors.transparent;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: isCurrent ? 1.6 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!unlocked)
                Icon(Icons.lock_rounded,
                    color: AppColors.muted.withOpacity(0.7), size: 22)
              else ...[
                Text(
                  '$id',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 12,
                      color: i < stars
                          ? AppColors.accent
                          : AppColors.muted.withOpacity(0.45),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
