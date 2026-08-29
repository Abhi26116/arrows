import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/game_controller.dart';
import '../models/arrow.dart';
import '../theme/app_theme.dart';
import 'arrow_glyph.dart';

typedef ArrowTap = void Function(int arrowId);

/// Paints the whole board in one layer — dense boards would otherwise need
/// hundreds of positioned widgets. Taps are mapped from cell coordinates.
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.session,
    required this.onTap,
    this.showGrid = false,
    this.hintId,
    this.animatingId,
    this.animArrow,
    this.animPath = const [],
    this.blockedId,
    this.blockedNonce = 0,
    this.onAnimComplete,
  });

  final PlaySession session;
  final ArrowTap onTap;
  final bool showGrid;
  final int? hintId;
  final int? animatingId;
  final ArrowPiece? animArrow;
  final List<(int, int)> animPath;
  final int? blockedId;

  /// Bumped on every blocked tap so a repeat tap re-triggers the shake.
  final int blockedNonce;
  final VoidCallback? onAnimComplete;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late AnimationController _flyController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onAnimComplete?.call();
        }
      });
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.hintId != null) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animatingId != null &&
        widget.animatingId != oldWidget.animatingId &&
        widget.animPath.length >= 2) {
      _flyController.forward(from: 0);
    }
    if (widget.blockedId != null &&
        widget.blockedNonce != oldWidget.blockedNonce) {
      _shakeController.forward(from: 0);
    }
    if (widget.hintId != oldWidget.hintId) {
      if (widget.hintId != null) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _flyController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Exact cell first; otherwise the nearest arrow within three quarters of a
  /// cell. Late boards have ~20pt cells, so a strict hit test would punish
  /// near-misses with a heart.
  ArrowPiece? _arrowNear(GameController c, Offset p, double cell) {
    final row = (p.dy / cell).floor();
    final col = (p.dx / cell).floor();
    final exact = c.arrowAt(row, col);
    if (exact != null) return exact;

    ArrowPiece? best;
    var bestDistance = cell * 0.75;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final near = c.arrowAt(row + dr, col + dc);
        if (near == null) continue;
        final center =
            Offset((col + dc + 0.5) * cell, (row + dr + 0.5) * cell);
        final distance = (center - p).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = near;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.session.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          constraints.maxWidth / c.cols,
          constraints.maxHeight / c.rows,
        );
        final boardW = cell * c.cols;
        final boardH = cell * c.rows;

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final hit = _arrowNear(c, details.localPosition, cell);
              if (hit != null) widget.onTap(hit.id);
            },
            child: CustomPaint(
              size: Size(boardW, boardH),
              painter: _BoardPainter(
                rows: c.rows,
                cols: c.cols,
                cell: cell,
                arrows: c.arrows.values.toList(),
                showGrid: widget.showGrid,
                lineColor: AppColors.arrowLine,
                gridColor: AppColors.gridLine,
                hintColor: AppColors.accent,
                blockedColor: AppColors.danger,
                hintId: widget.hintId,
                blockedId: widget.blockedId,
                animArrow: widget.animArrow,
                animSteps: math.max(0, widget.animPath.length - 1),
                fly: _flyController,
                shake: _shakeController,
                pulse: _pulseController,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.rows,
    required this.cols,
    required this.cell,
    required this.arrows,
    required this.showGrid,
    required this.lineColor,
    required this.gridColor,
    required this.hintColor,
    required this.blockedColor,
    required this.hintId,
    required this.blockedId,
    required this.animArrow,
    required this.animSteps,
    required this.fly,
    required this.shake,
    required this.pulse,
  }) : super(repaint: Listenable.merge([fly, shake, pulse]));

  final int rows;
  final int cols;
  final double cell;
  final List<ArrowPiece> arrows;
  final bool showGrid;
  final Color lineColor;
  final Color gridColor;
  final Color hintColor;
  final Color blockedColor;
  final int? hintId;
  final int? blockedId;
  final ArrowPiece? animArrow;
  final int animSteps;
  final Animation<double> fly;
  final Animation<double> shake;
  final Animation<double> pulse;

  Offset _center(int row, int col) =>
      Offset((col + 0.5) * cell, (row + 0.5) * cell);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular((cell * 0.5).clamp(10.0, 20.0)),
    );

    if (showGrid) {
      canvas.save();
      canvas.clipRRect(frame);
      final grid = Paint()
        ..color = gridColor.withOpacity(0.30)
        ..strokeWidth = 1;
      for (var r = 1; r < rows; r++) {
        canvas.drawLine(
            Offset(0, r * cell), Offset(size.width, r * cell), grid);
      }
      for (var c = 1; c < cols; c++) {
        canvas.drawLine(
            Offset(c * cell, 0), Offset(c * cell, size.height), grid);
      }
      canvas.restore();

      final border = Paint()
        ..color = gridColor.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(frame, border);
    }

    for (final arrow in arrows) {
      var color = lineColor;
      var glow = false;
      var shift = Offset.zero;

      if (arrow.id == hintId) {
        color = Color.lerp(lineColor, hintColor, 0.4 + 0.6 * pulse.value)!;
        glow = true;
      }
      if (arrow.id == blockedId && shake.isAnimating) {
        color = blockedColor;
        // Bumps into the blocker and settles back.
        final t = shake.value;
        final bump =
            math.sin(t * math.pi * 3) * cell * 0.22 * (1 - t).clamp(0.0, 1.0);
        shift = Offset(arrow.direction.dCol * bump, arrow.direction.dRow * bump);
      }

      _drawArrow(canvas, arrow, color, glow: glow, shift: shift);
    }

    final flying = animArrow;
    if (flying != null && fly.isAnimating && animSteps > 0) {
      final t = Curves.easeIn.transform(fly.value);
      final distance = animSteps * cell * t;
      final shift = Offset(
        flying.direction.dCol * distance,
        flying.direction.dRow * distance,
      );
      final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
      _drawArrow(canvas, flying, lineColor,
          glow: true, shift: shift, opacity: opacity);
    }
  }

  void _drawArrow(
    Canvas canvas,
    ArrowPiece arrow,
    Color color, {
    bool glow = false,
    Offset shift = Offset.zero,
    double opacity = 1,
  }) {
    paintArrowLine(
      canvas,
      tip: _center(arrow.row, arrow.col) + shift,
      tail: _center(arrow.tailRow, arrow.tailCol) + shift,
      direction: arrow.direction,
      color: color,
      cell: cell,
      glow: glow,
      opacity: opacity,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
