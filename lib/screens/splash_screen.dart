import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/direction.dart';
import '../services/ads_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arrow_glyph.dart';
import 'home_screen.dart';

/// Animated opener: a small board clears itself, arrow by arrow, and the
/// wordmark rises out of it. The native splash behind it is the same flat
/// navy, so the hand-off is seamless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1900);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _duration,
  );
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goHome();
    });
    _c.forward();
    _startAds();
  }

  /// Kicks off consent + ads start-up while the animation plays. Deliberately
  /// not awaited — the splash never waits on it, and any screen needing a
  /// banner joins the same run.
  void _startAds() {
    AdsService.instance.ensureInitialized();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _goHome() {
    if (_leaving || !mounted) return;
    _leaving = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const HomeScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: GestureDetector(
        // Nobody should have to sit through it twice.
        onTap: _goHome,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 280,
                    height: 200,
                    child: CustomPaint(
                      painter: _SplashBoardPainter(
                        t: t,
                        line: AppColors.arrowLine,
                        accent: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Opacity(
                    opacity: _fade(t, 0.52, 0.74),
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - _fade(t, 0.52, 0.74))),
                      child: Text(
                        'ARROWS',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontVariations: const [FontVariation('wght', 700)],
                          fontWeight: FontWeight.w700,
                          fontSize: 34,
                          letterSpacing: 2,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: _fade(t, 0.62, 0.82) * 0.9,
                    child: Text(
                      'Clear the board',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

double _fade(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

class _SplashBoardPainter extends CustomPainter {
  _SplashBoardPainter({
    required this.t,
    required this.line,
    required this.accent,
  });

  final double t;
  final Color line;
  final Color accent;

  /// (col, row, direction, length, enter, exit, isHero) on a 5x3 board.
  static const _arrows = <(int, int, Direction, int, double, double, bool)>[
    (0, 0, Direction.right, 2, 0.02, 0.62, false),
    (4, 0, Direction.down, 2, 0.10, 0.52, false),
    (0, 2, Direction.right, 3, 0.18, 0.42, true),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Arrows leave at the board edge, exactly as they do in play.
    canvas.clipRect(Offset.zero & size);

    const cols = 5, rows = 3;
    final cell = math.min(size.width / cols, size.height / rows);
    final originX = (size.width - cell * cols) / 2;
    final originY = (size.height - cell * rows) / 2;

    Offset centre(int col, int row) => Offset(
          originX + (col + 0.5) * cell,
          originY + (row + 0.5) * cell,
        );

    for (final (col, row, dir, length, enter, exit, isHero) in _arrows) {
      final appear = _fade(t, enter, enter + 0.18);
      if (appear <= 0) continue;

      var opacity = appear;
      var shift = Offset(0, (1 - appear) * cell * 0.35);

      final leaving = _fade(t, exit, exit + 0.22);
      if (leaving > 0) {
        final eased = Curves.easeInCubic.transform(leaving);
        final distance = (cols + length) * cell * eased;
        shift = Offset(dir.dCol * distance, dir.dRow * distance);
        opacity = (1 - _fade(t, exit + 0.10, exit + 0.22)).clamp(0.0, 1.0);
      }

      paintArrowLine(
        canvas,
        tip: centre(col + (dir == Direction.right ? length - 1 : 0),
                row + (dir == Direction.down ? length - 1 : 0)) +
            shift,
        tail: centre(col, row) + shift,
        direction: dir,
        color: isHero ? accent : line,
        cell: cell,
        opacity: opacity,
        glow: isHero && leaving == 0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBoardPainter oldDelegate) =>
      oldDelegate.t != t;
}
