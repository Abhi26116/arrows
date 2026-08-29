import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/direction.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';

/// Shared line-art arrow used by the board and by decorative glyphs.
///
/// Draws a rounded shaft from [tail] to [tip] (both are cell centres) plus a
/// chevron head at the tip, scaled to [cell].
void paintArrowLine(
  Canvas canvas, {
  required Offset tip,
  required Offset tail,
  required Direction direction,
  required Color color,
  required double cell,
  double opacity = 1,
  bool glow = false,
  double strokeFactor = 0.15,
}) {
  final u = Offset(direction.dCol.toDouble(), direction.dRow.toDouble());
  final perp = Offset(-u.dy, u.dx);
  // Clamped so tiny tutorial boards don't get slabs and dense boards stay legible.
  final stroke = (cell * strokeFactor).clamp(1.8, 8.0);
  final head = (cell * 0.32).clamp(3.0, 17.0);

  final start = tail - u * (cell * 0.32);
  final end = tip + u * (cell * 0.32);

  final shaft = Path()
    ..moveTo(start.dx, start.dy)
    ..lineTo(end.dx, end.dy);

  final chevron = Path()
    ..moveTo(end.dx - u.dx * head + perp.dx * head * 0.8,
        end.dy - u.dy * head + perp.dy * head * 0.8)
    ..lineTo(end.dx, end.dy)
    ..lineTo(end.dx - u.dx * head - perp.dx * head * 0.8,
        end.dy - u.dy * head - perp.dy * head * 0.8);

  final paint = Paint()
    ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  if (glow) {
    final glowPaint = Paint()
      ..color = color.withOpacity(0.38 * opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.6);
    canvas.drawPath(shaft, glowPaint);
    canvas.drawPath(chevron, glowPaint);
  }

  canvas.drawPath(shaft, paint);
  canvas.drawPath(chevron, paint);
}

/// Single decorative arrow (menus, how-to-play, hero art).
class ArrowGlyph extends StatelessWidget {
  const ArrowGlyph({
    super.key,
    required this.direction,
    required this.color,
    this.size = 28,
    this.glow = false,
  });

  final Direction direction;
  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: direction.angle,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GlyphPainter(color: color, glow: glow),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.color, required this.glow});

  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    paintArrowLine(
      canvas,
      // Drawn pointing right; the widget rotates it into place.
      tip: Offset(w * 0.72, h * 0.5),
      tail: Offset(w * 0.28, h * 0.5),
      direction: Direction.right,
      color: color,
      cell: w * 0.5,
      glow: glow,
      strokeFactor: 0.22,
    );
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}

/// Flat, quiet backdrop for the play screen — the board is the only artwork.
class BoardBackground extends StatelessWidget {
  const BoardBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgTop,
            AppColors.bgMid,
            AppColors.bgTop,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      // Wider than the menus allow: the board is square, so it earns the extra
      // room in a way a column of buttons does not.
      child: ContentBounds(wide: true, child: child),
    );
  }
}

/// Decorative mini board for menus — the same line art as the real game,
/// arranged by hand so Home reads as a board rather than loose arrows.
///
/// Each arrow drifts slowly along its own axis and the clearable one pulses,
/// so the board feels alive without pulling focus from the buttons.
class MiniBoardArt extends StatefulWidget {
  const MiniBoardArt({super.key, this.height = 150});

  final double height;

  /// (tipRow, tipCol, direction, length) on a 4x6 grid.
  static const arrows = <(int, int, Direction, int)>[
    (0, 0, Direction.left, 2),
    (0, 5, Direction.right, 3),
    (1, 0, Direction.left, 2),
    (2, 5, Direction.right, 2),
    (3, 2, Direction.down, 3),
    (3, 4, Direction.left, 2),
  ];

  @override
  State<MiniBoardArt> createState() => _MiniBoardArtState();
}

class _MiniBoardArtState extends State<MiniBoardArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MiniBoardPainter(
          color: AppColors.arrowLine,
          glowColor: AppColors.accent,
          drift: _drift,
        ),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  _MiniBoardPainter({
    required this.color,
    required this.glowColor,
    required this.drift,
  }) : super(repaint: drift);

  final Color color;
  final Color glowColor;
  final Animation<double> drift;

  static const _cols = 6;
  static const _rows = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.min(size.width / _cols, size.height / _rows);
    final originX = (size.width - cell * _cols) / 2;
    final originY = (size.height - cell * _rows) / 2;

    Offset centre(int row, int col) => Offset(
          originX + (col + 0.5) * cell,
          originY + (row + 0.5) * cell,
        );

    final t = drift.value * 2 * math.pi;

    for (var i = 0; i < MiniBoardArt.arrows.length; i++) {
      final (row, col, dir, length) = MiniBoardArt.arrows[i];
      // The top-right arrow has a clear run out, so it gets the hint glow.
      final highlighted = row == 0 && dir == Direction.right;

      // Each arrow sways along the way it points, offset in phase.
      final sway = math.sin(t + i * 1.05) * cell * 0.16;
      final shift = Offset(dir.dCol * sway, dir.dRow * sway);

      paintArrowLine(
        canvas,
        tip: centre(row, col) + shift,
        tail: centre(
              row - dir.dRow * (length - 1),
              col - dir.dCol * (length - 1),
            ) +
            shift,
        direction: dir,
        color: highlighted ? glowColor : color,
        cell: cell,
        glow: highlighted,
        opacity: highlighted
            ? 0.75 + 0.25 * (0.5 + 0.5 * math.sin(t * 1.5))
            : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBoardPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glowColor != glowColor;
}

class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgTop,
            AppColors.bgMid,
            AppColors.bgBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(color: AppColors.accent.withOpacity(0.12), size: 220),
          ),
          Positioned(
            bottom: 40,
            left: -70,
            child: _Blob(
              color: AppColors.arrowLine.withOpacity(0.1),
              size: 260,
            ),
          ),
          // The gradient and blobs stay full-bleed; only what sits on top is
          // held to a readable width, which is what keeps these phone layouts
          // from stretching across an iPad.
          Positioned.fill(child: ContentBounds(child: child)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}
