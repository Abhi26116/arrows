import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/arrow.dart';
import '../models/direction.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';

/// Stroke width as a fraction of a cell, and the clamp that keeps tiny
/// tutorial boards off slabs and dense boards legible.
const double kArrowStrokeFactor = 0.22;
const double kArrowStrokeMin = 2.0;
const double kArrowStrokeMax = 11.0;

/// How far the chevron head and the tail reach past their cell centres.
const double kArrowEndReach = 0.32;

double arrowStroke(double cell, {double factor = kArrowStrokeFactor}) =>
    (cell * factor).clamp(kArrowStrokeMin, kArrowStrokeMax);

/// Drops the points that sit in the middle of a straight run, leaving the
/// spine's corners. Rounding reads off the corners, so a 12-cell straight
/// shaft costs the same as a 1-cell one.
List<Offset> simplifySpine(List<Offset> points) {
  if (points.length < 3) return points;
  final out = <Offset>[points.first];
  for (var i = 1; i < points.length - 1; i++) {
    final a = points[i] - points[i - 1];
    final b = points[i + 1] - points[i];
    // Axis-aligned spines, so a sign flip on either axis is a real corner.
    if ((a.dx * b.dy - a.dy * b.dx).abs() > 0.001) out.add(points[i]);
  }
  out.add(points.last);
  return out;
}

/// Pushes both ends outward along their own segments, so the stroke fills the
/// arrow's end cells instead of stopping at their centres.
List<Offset> extendSpine(List<Offset> points, double by) {
  if (points.length < 2) return points;
  final out = List<Offset>.from(points);
  Offset unit(Offset v) {
    final d = v.distance;
    return d == 0 ? Offset.zero : v / d;
  }

  out[0] = out[0] + unit(out[0] - out[1]) * by;
  final last = out.length - 1;
  out[last] = out[last] + unit(out[last] - out[last - 1]) * by;
  return out;
}

/// The stretch of [points] between two arc-length positions, used to slide a
/// bent arrow along its own track as it leaves the board.
List<Offset> slicePolyline(List<Offset> points, double from, double to) {
  if (points.length < 2 || to <= from) return const [];
  final out = <Offset>[];
  var walked = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    final len = (b - a).distance;
    if (len == 0) continue;
    final segStart = walked;
    walked += len;
    if (walked < from || segStart > to) continue;
    final t0 = ((from - segStart) / len).clamp(0.0, 1.0);
    final t1 = ((to - segStart) / len).clamp(0.0, 1.0);
    final p0 = Offset.lerp(a, b, t0)!;
    final p1 = Offset.lerp(a, b, t1)!;
    if (out.isEmpty) out.add(p0);
    if ((p1 - out.last).distance > 0.01) out.add(p1);
  }
  return out;
}

/// Shaft and chevron head as one path, with the corners rounded off so a bent
/// body reads as a single pipe rather than stacked sticks.
///
/// [spine] runs tip first, tail last, in cell centres; the ends are pushed
/// outward for you.
Path buildArrowPath({
  required List<Offset> spine,
  required Direction direction,
  required double cell,
}) {
  final path = Path();
  if (spine.isEmpty) return path;

  final u = Offset(direction.dCol.toDouble(), direction.dRow.toDouble());
  final reach = cell * kArrowEndReach;

  var spun = simplifySpine(spine);
  if (spun.length == 1) {
    // A single-cell arrow has no spine to speak of. Give it a hair of length
    // along its own axis so pushing the ends out leaves the same short stub
    // the rest of the board draws.
    spun = [spun.first, spun.first - u * (cell * 0.02)];
  }
  final points = extendSpine(spun, reach);

  final radius = cell * 0.45;
  path.moveTo(points.last.dx, points.last.dy);
  // Walked tail to tip so the head lands on the end of the stroke.
  for (var i = points.length - 2; i >= 1; i--) {
    final prev = points[i + 1];
    final cur = points[i];
    final next = points[i - 1];
    final inVec = cur - prev;
    final outVec = next - cur;
    final inLen = inVec.distance;
    final outLen = outVec.distance;
    if (inLen == 0 || outLen == 0) continue;
    final r = math.min(radius, math.min(inLen, outLen) / 2);
    final a = cur - inVec / inLen * r;
    final b = cur + outVec / outLen * r;
    path.lineTo(a.dx, a.dy);
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  final tip = points.first;
  path.lineTo(tip.dx, tip.dy);

  final perp = Offset(-u.dy, u.dx);
  final head = (cell * 0.34).clamp(3.5, 18.0);
  path
    ..moveTo(tip.dx - u.dx * head + perp.dx * head * 0.8,
        tip.dy - u.dy * head + perp.dy * head * 0.8)
    ..lineTo(tip.dx, tip.dy)
    ..lineTo(tip.dx - u.dx * head - perp.dx * head * 0.8,
        tip.dy - u.dy * head - perp.dy * head * 0.8);

  return path;
}

/// Lays a neon-sign stroke down in passes: a wide soft bloom, a tighter halo,
/// the solid core, then a pale centre line that gives the stroke its tube
/// look. Batch a whole board into one [path] — the blur costs the same for
/// sixty arrows as for one, and overlaps blend once instead of stacking.
void strokeNeon(
  Canvas canvas,
  Path path, {
  required Color color,
  required double stroke,
  double opacity = 1,
  bool bloom = true,
  bool bright = false,
}) {
  final a = opacity.clamp(0.0, 1.0);
  if (a <= 0) return;

  Paint pass(double widthScale, double alpha, double blur) {
    final p = Paint()
      ..color = color.withOpacity((alpha * a).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * widthScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (blur > 0) {
      p.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * blur);
    }
    return p;
  }

  if (bloom) {
    canvas.drawPath(path, pass(3.4, bright ? 0.34 : 0.20, 1.7));
  }
  canvas.drawPath(path, pass(1.7, bright ? 0.52 : 0.32, 0.7));
  canvas.drawPath(path, pass(1, 1, 0));
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white.withOpacity((bright ? 0.42 : 0.22) * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

/// Shared line-art arrow used by decorative glyphs and the splash screen.
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
  double strokeFactor = kArrowStrokeFactor,
}) {
  final path = buildArrowPath(
    spine: [tip, tail],
    direction: direction,
    cell: cell,
  );
  strokeNeon(
    canvas,
    path,
    color: color,
    stroke: arrowStroke(cell, factor: strokeFactor),
    opacity: opacity,
    bloom: glow,
    bright: glow,
  );
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
///
/// A single soft pool of the line colour sits behind the board so the neon
/// reads as lit rather than pasted onto the black.
class BoardBackground extends StatelessWidget {
  const BoardBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.bgTop),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 0.95,
                    colors: [
                      AppColors.arrowLine.withOpacity(0.09),
                      AppColors.arrowLine.withOpacity(0.02),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          // Wider than the menus allow: the board is square, so it earns the
          // extra room in a way a column of buttons does not.
          Positioned.fill(child: ContentBounds(wide: true, child: child)),
        ],
      ),
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

  /// Hand-placed on a 4x6 grid, bends included, so Home advertises the shape
  /// of the real boards.
  static final arrows = <ArrowPiece>[
    ArrowPiece(id: 0, row: 0, col: 0, direction: Direction.left, length: 2),
    ArrowPiece(id: 1, row: 0, col: 5, direction: Direction.right, length: 3),
    ArrowPiece(
      id: 2,
      row: 1,
      col: 0,
      direction: Direction.left,
      length: 3,
      bends: [(Direction.down, 2)],
    ),
    ArrowPiece(id: 3, row: 2, col: 5, direction: Direction.right, length: 2),
    ArrowPiece(
      id: 4,
      row: 3,
      col: 2,
      direction: Direction.down,
      length: 3,
      bends: [(Direction.right, 2)],
      accent: true,
    ),
    ArrowPiece(id: 5, row: 3, col: 4, direction: Direction.left, length: 2),
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
          accentColor: AppColors.arrowAccent,
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
    required this.accentColor,
    required this.glowColor,
    required this.drift,
  }) : super(repaint: drift);

  final Color color;
  final Color accentColor;
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
    final stroke = arrowStroke(cell);

    for (var i = 0; i < MiniBoardArt.arrows.length; i++) {
      final arrow = MiniBoardArt.arrows[i];
      // The top-right arrow has a clear run out, so it gets the hint glow.
      final highlighted = arrow.row == 0 && arrow.direction == Direction.right;

      // Each arrow sways along the way it points, offset in phase.
      final sway = math.sin(t + i * 1.05) * cell * 0.16;
      final shift = Offset(
        arrow.direction.dCol * sway,
        arrow.direction.dRow * sway,
      );

      strokeNeon(
        canvas,
        buildArrowPath(
          spine: [
            for (final (r, c) in arrow.cells) centre(r, c) + shift,
          ],
          direction: arrow.direction,
          cell: cell,
        ),
        color: highlighted
            ? glowColor
            : (arrow.accent ? accentColor : color),
        stroke: stroke,
        bright: highlighted,
        opacity:
            highlighted ? 0.75 + 0.25 * (0.5 + 0.5 * math.sin(t * 1.5)) : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBoardPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.glowColor != glowColor;
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
            child: _Blob(color: AppColors.accent.withOpacity(0.14), size: 220),
          ),
          Positioned(
            bottom: 40,
            left: -70,
            child: _Blob(
              color: AppColors.arrowLine.withOpacity(0.12),
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
