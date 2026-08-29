import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/progress_store.dart';
import '../logic/game_controller.dart';
import '../logic/level_generator.dart';
import '../models/arrow.dart';
import '../models/level.dart';
import '../services/ads_service.dart';
import '../services/leaderboard_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arrow_glyph.dart';
import '../widgets/app_chrome.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.levelId,
    this.customLevel,
    this.isDaily = false,
  }) : assert(levelId != null || customLevel != null);

  final int? levelId;
  final LevelData? customLevel;
  final bool isDaily;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Width of the button cluster on each side of the header title.
const double _sideCluster = 48 * 2 + 10;

class _GameScreenState extends State<GameScreen> {
  late PlaySession _session;
  int? _hintId;
  int? _animatingId;
  List<(int, int)> _animPath = const [];
  ArrowPiece? _animArrow;
  int? _blockedId;
  int _blockedNonce = 0;
  bool _busy = false;
  bool _won = false;
  bool _gameOver = false;
  int _hintsUsed = 0;
  bool _showGrid = false;

  LevelData get _level =>
      widget.customLevel ?? LevelCatalog.byId(widget.levelId!);

  @override
  void initState() {
    super.initState();
    _showGrid = AppStore.instance.showGrid;
    _load();
  }

  void _load() {
    _session = PlaySession(_level.clone());
    _hintId = null;
    _animatingId = null;
    _animPath = const [];
    _animArrow = null;
    _blockedId = null;
    _busy = false;
    _won = false;
    _gameOver = false;
    _hintsUsed = 0;
  }

  Future<void> _onTap(int arrowId) async {
    if (_busy || _won || _gameOver) return;
    final preview = _session.controller.preview(arrowId);
    if (preview.result == MoveResult.invalid) return;

    if (preview.result == MoveResult.blocked) {
      SoundService.instance.play(Sfx.blocked);
      SoundService.instance.hapticHeavy();
      _session.tap(arrowId);
      setState(() {
        _blockedId = arrowId;
        _blockedNonce++;
      });
      Future.delayed(const Duration(milliseconds: 460), () {
        if (!mounted) return;
        setState(() => _blockedId = null);
        if (_session.isOutOfLives && !_gameOver) {
          _gameOver = true;
          _showGameOver();
        }
      });
      return;
    }

    final arrow = _session.controller.arrows[arrowId]!.copy();
    setState(() {
      _busy = true;
      _hintId = null;
      _animatingId = arrowId;
      _animPath = preview.path;
      _animArrow = arrow;
    });

    _session.tap(arrowId);
    SoundService.instance.play(Sfx.clear);
    SoundService.instance.hapticSelection();
  }

  Future<void> _onAnimComplete() async {
    setState(() {
      _animatingId = null;
      _animPath = const [];
      _animArrow = null;
      _busy = false;
    });

    if (_session.controller.isWon) {
      _won = true;
      final stars = _calcStars();
      SoundService.instance.play(Sfx.win);
      SoundService.instance.hapticMedium();
      if (widget.isDaily) {
        await AppStore.instance.recordDaily(stars);
      } else if (widget.levelId != null) {
        await AppStore.instance.completeLevel(widget.levelId!, stars: stars);
      }
      await LeaderboardService.instance.submitScore();
      if (!mounted) return;
      await _showWin(stars);
      await AdsService.instance.maybeShowInterstitialAfterWin();
      if (mounted) await _maybeAskForReview();
    } else {
      setState(() {});
    }
  }

  /// One star per heart still beating.
  int _calcStars() => _session.lives.clamp(1, PlaySession.maxLives);

  /// Only ever after a win, and only after enough boards that the player has
  /// an opinion worth giving. [ReviewService] decides; this just asks nicely
  /// first, so nobody is dropped into the store's own sheet unprompted.
  Future<void> _maybeAskForReview() async {
    if (!await ReviewService.instance
        .shouldAsk(AppStore.instance.clearedCount)) {
      return;
    }
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final rate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.reviewTitle,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l.reviewBody,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(l.reviewLater, style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.reviewRate),
          ),
        ],
      ),
    );
    if (rate == true) {
      await ReviewService.instance.accepted();
    } else {
      await ReviewService.instance.declined();
    }
  }

  Future<void> _showWin(int stars) async {
    final hasNext = !widget.isDaily &&
        widget.levelId != null &&
        widget.levelId! < LevelCatalog.count;
    await _showPanel(
      barrierDismissible: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.isDaily ? 'DAILY CLEAR' : 'CLEARED',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontVariations: const [FontVariation('wght', 700)],
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _level.label ?? 'Level ${widget.levelId}',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            '${_session.mistakes} miss · $_hintsUsed hint',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final on = i < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  on ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: on ? AppColors.accent : AppColors.muted,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(_load);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.surfaceHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Replay'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (hasNext) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GameScreen(levelId: widget.levelId! + 1),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(hasNext ? 'Next' : 'Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showGameOver() async {
    SoundService.instance.play(Sfx.blocked);
    await _showPanel(
      barrierDismissible: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.danger, size: 34),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'OUT OF HEARTS',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontVariations: const [FontVariation('wght', 700)],
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_session.cleared} of ${_session.totalArrows} arrows cleared',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final earned =
                    await AdsService.instance.showRewardedForExtraLife();
                if (!mounted) return;
                if (!earned) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No ad ready — try again.')),
                  );
                  return;
                }
                Navigator.pop(context);
                setState(() {
                  _session.grantLife();
                  _gameOver = false;
                });
              },
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: const Text('Extra heart'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.surfaceHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Quit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(_load);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.surfaceHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPanel({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'panel',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim, secondary) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceHigh),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _hint() async {
    final ids = _session.controller.clearableArrowIds();
    if (ids.isEmpty) return;

    // Prefer free/bonus hints; otherwise offer rewarded ad.
    final hasBonus = await AppStore.instance.consumeBonusHint();
    if (!hasBonus && AppStore.instance.adsEnabled && _hintsUsed >= 1) {
      final earned = await AdsService.instance.showRewardedForHint();
      if (!earned) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Watch a short ad in Shop for bonus hints, or try again.'),
          ),
        );
        return;
      }
      await AppStore.instance.consumeBonusHint();
    }

    SoundService.instance.play(Sfx.hint);
    SoundService.instance.hapticLight();
    setState(() {
      _hintId = ids.first;
      _hintsUsed++;
    });
  }

  /// Restarting throws away a board in progress, so ask first once the player
  /// has actually made moves.
  /// Asked before a board in progress is abandoned. Returns whether to leave.
  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Leave this board?',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'It starts from the beginning next time.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Keep playing', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _confirmRestart() async {
    SoundService.instance.hapticSelection();
    if (_session.moves == 0 && _session.mistakes == 0) {
      setState(_load);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Restart board?',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Every arrow comes back and your hearts reset.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Keep playing', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restart', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      SoundService.instance.hapticMedium();
      setState(_load);
    }
  }

  void _toggleGrid() {
    SoundService.instance.hapticSelection();
    setState(() => _showGrid = !_showGrid);
    AppStore.instance.setShowGrid(_showGrid);
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final title = widget.isDaily ? 'Daily' : level.difficulty;
    final subtitle = widget.isDaily ? 'TODAY' : 'LEVEL ${level.id}';

    return PopScope(
      // A board in progress lives only in memory, so leaving throws away
      // however far in the player was. Restarting already asks; Android's back
      // gesture is far easier to hit by accident than either button, so it has
      // to ask too. An untouched board leaves without comment.
      canPop: _won || (_session.moves == 0 && _session.mistakes == 0),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Scaffold(
        body: BoardBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Both side clusters are the same width, so the title
                      // column centres on the screen and not between them.
                      SizedBox(
                        width: _sideCluster,
                        child: Row(
                          children: [
                            CircleIconButton(
                              icon: Icons.play_arrow_rounded,
                              flipped: true,
                              tooltip: 'Back',
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 10),
                            CircleIconButton(
                              icon: Icons.undo_rounded,
                              tooltip: 'Undo',
                              onTap: _busy || !_session.canUndo
                                  ? null
                                  : () {
                                      if (_session.undo()) {
                                        SoundService.instance.hapticSelection();
                                        setState(() {
                                          _hintId = null;
                                          _won = false;
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Difficulty words vary in width and the bold face
                            // is wide — scale down instead of wrapping.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                title,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontVariations: const [
                                    FontVariation('wght', 700)
                                  ],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _Hearts(lives: _session.lives),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: _sideCluster,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CircleIconButton(
                            icon: Icons.cleaning_services_rounded,
                            tooltip: 'Restart board',
                            onTap: _busy ? null : _confirmRestart,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(child: _ProgressBar(value: _session.progress)),
                      const SizedBox(width: 12),
                      Text(
                        '${_session.cleared}/${_session.totalArrows}',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // Extra bottom padding lifts the board clear of the
                      // floating buttons and balances the header above it.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 92),
                        child: GameBoard(
                          session: _session,
                          onTap: _onTap,
                          showGrid: _showGrid,
                          hintId: _hintId,
                          animatingId: _animatingId,
                          animArrow: _animArrow,
                          animPath: _animPath,
                          blockedId: _blockedId,
                          blockedNonce: _blockedNonce,
                          onAnimComplete: _onAnimComplete,
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          children: [
                            CircleIconButton(
                              icon: Icons.lightbulb_outline_rounded,
                              accent: true,
                              tooltip: 'Hint',
                              onTap: _busy ? null : _hint,
                            ),
                            const SizedBox(height: 12),
                            CircleIconButton(
                              icon: Icons.grid_on_rounded,
                              active: _showGrid,
                              tooltip: _showGrid ? 'Hide grid' : 'Show grid',
                              onTap: _toggleGrid,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hearts extends StatelessWidget {
  const _Hearts({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(PlaySession.maxLives, (i) {
        final alive = i < lives;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedScale(
            scale: alive ? 1 : 0.82,
            duration: const Duration(milliseconds: 220),
            child: Icon(
              alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color:
                  alive ? AppColors.danger : AppColors.muted.withOpacity(0.45),
            ),
          ),
        );
      }),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final filled = value > 0.001;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 5,
        color: AppColors.surfaceHigh.withOpacity(0.5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    AppColors.arrowLine.withOpacity(0.75),
                    AppColors.arrowLine,
                  ],
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppColors.arrowLine.withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
