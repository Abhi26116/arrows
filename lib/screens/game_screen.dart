import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import 'package:arrows_game/l10n/app_localizations.dart';

import '../data/progress_store.dart';
import '../logic/game_controller.dart';
import '../logic/level_generator.dart';
import '../models/arrow.dart';
import '../models/level.dart';
import '../config/app_config.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/iap_service.dart';
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

/// Gap between the board and the screen edge. Small on purpose: the board is
/// square, so its width is what sizes it on a phone, and every point of
/// padding is a point off every cell.
const double _boardGutter = 4;

/// Height the floating hint and grid buttons need in the bottom-right.
const double _buttonBand = 120;

/// Width the same buttons take in from the right edge — their 16pt margin,
/// the button itself, and a little air before the board.
const double _buttonColumn = 16 + 48 + 8;

/// Where the board sits in the space under the progress bar: how big it is,
/// and how far down that space it starts.
///
/// The board is centred in that space. The one thing allowed to move it off
/// centre is the pair of floating buttons in the bottom-right corner: a board
/// that would run into them is lifted just far enough to clear them, and no
/// further. Shrinking it instead would cost every cell on the board for the
/// sake of the empty space around it.
@visibleForTesting
({double side, double top}) placeBoard(Size space) {
  // The largest square that clears the buttons by ending above them — what a
  // phone has room for, since its board is as wide as the screen.
  final above = math.min(
    space.width - _boardGutter * 2,
    space.height - _boardGutter - _buttonBand,
  );
  // The largest that clears them by staying out of their column, using the
  // full height instead — what a landscape tablet has room for.
  final beside = math.min(
    space.height - _boardGutter * 2,
    space.width - _buttonColumn * 2,
  );
  final side = math.max(0.0, math.max(above, beside));
  final reachesButtons = side > space.width - _buttonColumn * 2;
  final lowest =
      space.height - side - (reachesButtons ? _buttonBand : _boardGutter);
  final top = ((space.height - side) / 2)
      .clamp(_boardGutter, math.max(_boardGutter, lowest))
      .toDouble();
  return (side: side, top: top);
}

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
    // Hints bought or earned elsewhere land in the store; the badge follows.
    AppStore.instance.addListener(_onStoreChanged);
    _load();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onStoreChanged);
    super.dispose();
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
    Analytics.instance.track('level_start', _eventProps);
  }

  /// Which board an event is about.
  Map<String, Object?> get _eventProps => widget.isDaily
      ? const {'mode': 'daily'}
      : {'mode': 'campaign', 'level': _level.id};

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
          Analytics.instance.track('level_fail', {
            ..._eventProps,
            'cleared': _session.cleared,
            'total': _session.totalArrows,
          });
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
      Analytics.instance.track(widget.isDaily ? 'daily_win' : 'level_win', {
        ..._eventProps,
        'stars': stars,
        'mistakes': _session.mistakes,
        'hints': _hintsUsed,
      });
      if (!mounted) return;
      // The rating sheet goes up over the win panel, while the player is
      // looking at their stars — not after they have tapped Next and moved
      // on, by which time this screen is already being replaced. A win that
      // asks for a rating skips its interstitial: one interruption is enough.
      final askReview = await ReviewService.instance.shouldAsk(
        totalCleared: AppStore.instance.clearedCount,
        stars: stars,
      );
      if (askReview) {
        Analytics.instance.track('review_asked');
        Future.delayed(
          const Duration(milliseconds: 900),
          ReviewService.instance.request,
        );
      }
      if (!mounted) return;
      await _showWin(stars);
      await AdsService.instance.maybeShowInterstitialAfterWin(skip: askReview);
    } else {
      setState(() {});
    }
  }

  /// One star per heart still beating.
  int _calcStars() => _session.lives.clamp(1, PlaySession.maxLives);

  Future<void> _showWin(int stars) async {
    final l = AppLocalizations.of(context);
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
              widget.isDaily ? l.gameDailyClear : l.gameCleared,
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
            _level.label ?? l.gameLevelLabel(widget.levelId ?? 0),
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            l.gameMissHint(_session.mistakes, _hintsUsed),
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
                  child: Text(l.gameReplay),
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
                  child: Text(hasNext ? l.gameNext : l.gameDone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showGameOver() async {
    final l = AppLocalizations.of(context);
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
              l.gameOutOfHearts,
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
            l.gameArrowsCleared(_session.cleared, _session.totalArrows),
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final earned =
                    await AdsService.instance.showRewardedForExtraLife();
                Analytics.instance.track('extra_life', {
                  ..._eventProps,
                  'earned': earned ? 'yes' : 'no',
                });
                if (!mounted) return;
                if (!earned) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.gameNoAdReady)),
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
              label: Text(l.gameExtraHeart),
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
                  child: Text(l.gameQuit),
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
                  child: Text(l.gameRetry),
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

  /// The first hint on every board is free. After that a hint comes from
  /// the bonus stock — earned from ads or bought — and when that is empty the
  /// player is offered both ways to refill it.
  Future<void> _hint() async {
    final ids = _session.controller.clearableArrowIds();
    if (ids.isEmpty) return;

    String source;
    if (_hintsUsed == 0) {
      source = 'free';
    } else if (await AppStore.instance.consumeBonusHint()) {
      source = 'bonus';
    } else {
      if (!await _refillHints()) return;
      if (!await AppStore.instance.consumeBonusHint()) return;
      source = 'ad';
    }
    if (!mounted) return;

    Analytics.instance.track('hint', {..._eventProps, 'source': source});
    SoundService.instance.play(Sfx.hint);
    SoundService.instance.hapticLight();
    setState(() {
      _hintId = ids.first;
      _hintsUsed++;
    });
  }

  /// Out of hints: watch an ad for one, or buy a pack. Returns whether a hint
  /// was earned right here — a purchase lands later, through the store, and
  /// the player taps Hint again once it has.
  Future<bool> _refillHints() async {
    final l = AppLocalizations.of(context);
    final pack = IapService.instance.product(AppConfig.iapHints15);
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
              Icon(Icons.lightbulb_rounded,
                  color: AppColors.accentSoft, size: 30),
              const SizedBox(height: 8),
              Text(
                l.hintOutTitle,
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
                l.hintOutBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'ad'),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: Text(l.hintOutWatch),
              ),
              if (pack != null) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'buy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.surfaceHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l.hintOutBuy(15, pack.price)),
                ),
              ],
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
    if (!mounted) return false;

    if (choice == 'buy') {
      await IapService.instance.buy(AppConfig.iapHints15);
      return false;
    }
    if (choice != 'ad') return false;

    final earned = await AdsService.instance.showRewardedForHint();
    if (!earned && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.shopAdNotReady)),
      );
    }
    return earned;
  }

  /// Restarting throws away a board in progress, so ask first once the player
  /// has actually made moves.
  /// Asked before a board in progress is abandoned. Returns whether to leave.
  Future<bool> _confirmLeave() async {
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l.gameLeaveTitle,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l.gameLeaveBody,
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.gameKeepPlaying,
                style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.gameLeave, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _confirmRestart() async {
    final l = AppLocalizations.of(context);
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
          l.gameRestartTitle,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l.gameRestartBody,
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.gameKeepPlaying,
                style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text(l.gameRestart, style: TextStyle(color: AppColors.accent)),
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
    final l = AppLocalizations.of(context);
    final level = _level;
    final title = widget.isDaily ? l.navDaily : level.difficulty;
    final subtitle = widget.isDaily ? l.gameToday : l.gameLevelNumber(level.id);

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
                              tooltip: l.tooltipBack,
                              onTap: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 10),
                            CircleIconButton(
                              icon: Icons.undo_rounded,
                              tooltip: l.gameTooltipUndo,
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
                            tooltip: l.gameTooltipRestart,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final board = placeBoard(constraints.biggest);
                      return Stack(
                        children: [
                          Positioned(
                            left: _boardGutter,
                            right: _boardGutter,
                            top: board.top,
                            height: board.side,
                            child: Center(
                              child: SizedBox.square(
                                dimension: board.side,
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
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Column(
                              children: [
                                _HintButton(
                                  ready: (_hintsUsed == 0 ? 1 : 0) +
                                      AppStore.instance.bonusHints,
                                  tooltip: l.gameTooltipHint,
                                  onTap: _busy ? null : _hint,
                                ),
                                const SizedBox(height: 12),
                                CircleIconButton(
                                  icon: Icons.grid_on_rounded,
                                  active: _showGrid,
                                  tooltip: _showGrid
                                      ? l.gameTooltipHideGrid
                                      : l.gameTooltipShowGrid,
                                  onTap: _toggleGrid,
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

/// The hint button, with a badge for how many hints are ready to use — or a
/// small play mark when the next one comes from an ad.
class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.ready,
    required this.tooltip,
    required this.onTap,
  });

  final int ready;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleIconButton(
          icon: Icons.lightbulb_outline_rounded,
          accent: true,
          tooltip: tooltip,
          onTap: onTap,
        ),
        Positioned(
          top: -4,
          right: -4,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              // A count may need room; the play mark sits in a round badge.
              padding: EdgeInsets.symmetric(horizontal: ready > 0 ? 5 : 0),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.bgBottom, width: 1.5),
              ),
              alignment: Alignment.center,
              child: ready > 0
                  ? Text(
                      ready > 99 ? '99+' : '$ready',
                      style: TextStyle(
                        color: AppColors.bgBottom,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    )
                  : Icon(Icons.play_arrow_rounded,
                      size: 13, color: AppColors.bgBottom),
            ),
          ),
        ),
      ],
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
